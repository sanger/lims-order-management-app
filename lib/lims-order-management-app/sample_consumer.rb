require 'lims-busclient'
require 'common'
require 'lims-order-management-app/sample_json_decoder'
require 'lims-order-management-app/order_creator'

module Lims::OrderManagementApp
  class SampleConsumer
    include Lims::BusClient::Consumer
    include Virtus
    include Aequitas

    attribute :queue_name, String, :required => true, :writer => :private, :reader => :private
    attribute :log, Object, :required => true, :writer => :private, :reader => :private
    attribute :order_creator, OrderCreator, :required => true, :writer => :private, :reader => :private

    SampleNotPublished = Class.new(StandardError)
    SAMPLE_PUBLISHED_STATE = "published"
    EXPECTED_ROUTING_KEY_PATTERNS = [
      '*.*.sample.create', '*.*.sample.updatesample', 
      '*.*.bulkcreatesample.*', '*.*.bulkupdatesample.*' 
    ].map { |k| Regexp.new(k.gsub(/\./, "\\.").gsub(/\*/, ".*")) }

    def initialize(amqp_settings, api_settings)
      @queue_name = amqp_settings.delete("queue_name")
      consumer_setup(amqp_settings)
      @order_creator = OrderCreator.new(api_settings)
      set_queue
    end

    def set_logger(logger)
      @log = logger
    end

    private

    def before_filter(sample)
      raise SampleNotPublished if sample.state != SAMPLE_PUBLISHED_STATE
    end

    def set_queue
      self.add_queue(queue_name) do |metadata, payload|
        if expected_message?(metadata.routing_key)
          begin
            sample = sample_resource(payload) 
            before_filter(sample)
            pipeline = matching_rule(sample)
            order_creator.execute(sample, pipeline)
          rescue SampleNotPublished, NonMatchingRule
           metadata.reject  
          else
            metadata.ack
          end
        end
      end
    end

    def expected_message?(routing_key)
      EXPECTED_ROUTING_KEY_PATTERNS.each do |pattern|
        return true if routing_key.match(pattern)
      end
      false
    end
  end
end
