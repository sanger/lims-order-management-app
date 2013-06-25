require 'common'
require 'lims-order-management-app/helpers/api'
require 'lims-order-management-app/rule_matcher'


module Lims::OrderManagementApp
  class OrderCreator
    include Virtus
    include Aequitas
    include Helpers::API
    include Lims::OrderManagementApp::RuleMatcher

    TubeNotFound = Class.new(StandardError)

    attribute :input_tube_role, String, :required => true, :writer => :private
    attribute :user_uuid, String, :required => true, :writer => :private
    attribute :study_uuid, String, :required => true, :writer => :private
    attribute :cost_code, String, :required => true, :writer => :private

    # @param [Hash] api_settings
    def initialize(order_settings, api_settings, rule_settings)
      url = api_settings["url"]      
      @input_tube_role = order_settings["input_tube_role"]
      @user_uuid = order_settings["user_uuid"]
      @study_uuid = order_settings["study_uuid"]
      @cost_code = order_settings["cost_code"]
      initialize_api(url)
      initialize_rules(rule_settings)
    end

    # @param [Array] samples
    def execute(samples)
      sample_uuid_to_roles = Hash[samples.map { |s| [s[:uuid], matching_rule(s[:sample])] }]
      tube_uuids_to_roles = tubes_for_samples(sample_uuid_to_roles)
      order_parameters = generate_order_parameters(tube_uuids_to_roles)
      post_order(order_parameters)
    end

    private

    # @param [Map] sample UUID to role in order
    # @return [Map] tube UUID to role in order
    # Return a map from tube UUID for the given samples, to the role in the order that it should take
    def tubes_for_samples(sample_uuid_to_roles)
      parameters = {:search => {
        :description => "search for tubes by sample uuids",
        :model => "tube",
        :criteria => {
          :sample => {:uuid => sample_uuid_to_roles.keys}
        }
      }}
      search = post(url_for("laboratory-searches", :create), parameters)
      result_url = search["search"]["actions"]["first"]
      result = get(result_url)

      sample_uuids_in_tubes = [].tap do |uuids|
        result["tubes"].each do |tube|
          tube["aliquots"].each do |aliquot|
            uuids << aliquot["sample"]["uuid"]
          end
        end
      end.uniq

      orphan_sample_uuids = sample_uuid_to_roles.keys - sample_uuids_in_tubes
      raise TubeNotFound, "Can't find a tube containing the samples #{orphan_sample_uuids.to_s}" unless orphan_sample_uuids.empty? 
      Hash[result['tubes'].map { |t| [t['uuid'], sample_uuid_to_roles[t['aliquots'].first['sample']['uuid']]] }]
    end

    # @param [Map] tube UUID to role in order
    # @return [Hash]
    def generate_order_parameters(tube_uuid_to_role)
      role_to_tube_uuids = tube_uuid_to_role.inject(Hash.new { |h,k| h[k] = [] }) do |m,(k,v)|
        m[v] << k
        m
      end

      {:order => {}.tap do |p|
        p[:user_uuid] = user_uuid 
        p[:study_uuid] = study_uuid 
        p[:pipeline] = 'Samples'
        p[:cost_code] = cost_code 
        p[:sources] = role_to_tube_uuids
      end
      }
    end

    # @param [Hash] order_parameters
    def post_order(order_parameters)
      post(url_for(:orders, :create), order_parameters)
    end
  end
end
