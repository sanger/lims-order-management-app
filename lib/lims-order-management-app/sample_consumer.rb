require 'lims-busclient'
require 'common'
require 'lims-order-management-app/sample_json_decoder'

module Lims::OrderManagementApp
  class SampleConsumer
    include Lims::BusClient::Consumer
    include Virtus
    include Aequitas

    attribute :queue_name, String, :required => true, :writer => :private, :reader => :private
    attribute :log, Object, :required => true, :writer => :private, :reader => :private

    EXPECTED_ROUTING_KEY_PATTERNS = [
      '*.*.sample.create', '*.*.sample.updatesample', 
      '*.*.bulkcreatesample.*', '*.*.bulkupdatesample.*' 
    ].map { |k| Regexp.new(k.gsub(/\./, "\\.").gsub(/\*/, ".*")) }

    def initialize(amqp_settings, api_settings)
      @queue_name = amqp_settings.delete("queue_name")
      consumer_setup(amqp_settings)
      set_queue
    end

    def set_logger(logger)
      @log = logger
    end

    private

    def set_queue
      self.add_queue(queue_name) do |metadata, payload|
        if expected_message?(metadata.routing_key)
          sample = sample_resource(payload) 
          
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
