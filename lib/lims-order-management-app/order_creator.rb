require 'common'
require 'lims-order-management-app/helpers/api'
require 'lims-order-management-app/rule_matcher'

module Lims::OrderManagementApp
  class OrderCreator
    include Virtus
    include Aequitas
    include Helpers::API
    include Lims::OrderManagementApp::RuleMatcher

    SampleContainerNotFound = Class.new(StandardError)

    attribute :user_email, String, :required => true, :writer => :private
    attribute :study_uuid, String, :required => true, :writer => :private
    attribute :cost_code, String, :required => true, :writer => :private

    # @param [Hash] api_settings
    def initialize(order_settings, api_settings, rule_settings)
      url = api_settings["url"]      
      @user_email = order_settings["user_email"]
      @study_uuid = order_settings["study_uuid"]
      @cost_code = order_settings["cost_code"]
      initialize_api(url, @user_email)
      initialize_rules(rule_settings)
    end

    # @param [Array] samples
    def create!(samples)
      sample_uuids_to_roles = Hash[samples.map { |s| [s[:uuid], matching_rule(s[:sample])] }]
      container_uuids_to_roles = containers_for_samples(sample_uuids_to_roles)
      order_parameters = order_creation_parameters(container_uuids_to_roles)
      post_order(order_parameters)
    end

    private

    # @param [Hash] sample_uuids_to_roles
    # @return [Hash]
    def containers_for_samples(sample_uuids_to_roles)
      model, result = nil, nil
      [:tube, :filter_paper, :plate].each do |m|
        result = search_for(m, sample_uuids_to_roles.keys)
        unless result.nil? || result.empty? 
          model = m
          break
        end
      end

      first_sample_in_each_container = []
      sample_uuids_in_containers = [].tap do |uuids|
        result.each do |container|
          first_sample_uuid_added = false
          foreach_aliquot_of(model, container) do |aliquot|
            sample_uuid = aliquot["sample"]["uuid"]
            uuids << sample_uuid
            unless first_sample_uuid_added
              first_sample_in_each_container << sample_uuid
              first_sample_uuid_added = true
            end
          end
        end
      end.uniq

      orphan_sample_uuids = sample_uuids_to_roles.keys - sample_uuids_in_containers
      raise SampleContainerNotFound, "Can't find a resource containing the samples #{orphan_sample_uuids.to_s}" unless orphan_sample_uuids.empty? 

      Hash[result.map { |t| [t['uuid'], sample_uuids_to_roles[first_sample_in_each_container.shift]] }]
    end

    # @param [String, Symbol] model
    # @param [Array] sample_uuids
    # @return [Array]
    def search_for(model, sample_uuids)
      model = model.to_s
      parameters = {:search => {
        :description => "search for #{model} by sample uuids",
        :model => model,
        :criteria => {
          :sample => {:uuid => sample_uuids}
        }
      }}
      search = post(url_for("laboratory-searches", :create), parameters)
      result_url = search["search"]["actions"]["first"]
      result = get(result_url)
      result["#{model}s"]
    end

    # @param [String, Symbol] model
    # @param [Hash] resource_hash
    # @param [Block] block
    def foreach_aliquot_of(model, resource_hash, &block)
      case model.to_sym
      when :tube, :filter_paper then resource_hash["aliquots"].each { |aliquot| block.call(aliquot) } 
      else
        resource_hash["wells"].each do |_, aliquots|
           aliquots.each { |aliquot| block.call(aliquot) }
        end
      end
    end

    # @param [Map] tube UUID to role in order
    # @return [Hash]
    def order_creation_parameters(container_uuids_to_roles)
      roles_to_container_uuids = container_uuids_to_roles.inject(Hash.new { |h,k| h[k] = [] }) do |m,(k,v)|
        m[v] << k
        m
      end

      {:order => {}.tap do |p|
        p[:study_uuid] = study_uuid 
        p[:pipeline] = 'Samples'
        p[:cost_code] = cost_code 
        p[:sources] = roles_to_container_uuids
      end
      }
    end

    # @param [Hash] order_parameters
    def post_order(order_parameters)
      post(url_for(:orders, :create), order_parameters)
    end
  end
end
