require 'rest_client'
require 'json'

module Lims::OrderManagementApp
  module Helpers
    module API

      HEADERS = {'Content-Type' => 'application/json', 'Accept' => 'application/json'}

      module Request
        def get(url)
          response = RestClient.get(url, HEADERS)
          JSON.parse(response)
        end

        # According to RestClient documentation, it is necessary 
        # to set multipart to true when sending custom headers.
        def post(url, parameters, extra_headers = {})
          extra_headers.merge!(:multipart => true) unless extra_headers.empty?
          response = RestClient.post(url, parameters.to_json, HEADERS.merge(extra_headers))
          JSON.parse(response)
        end
      end
      include Request

      def self.included(klass)
        klass.class_eval do
          attribute :root, String, :required => true, :writer => :private, :reader => :private
        end
      end

      def initialize_api(root_url)
        @root = get(root_url)        
      end

      def url_for(model, action)
        @root[model.to_s]["actions"][action.to_s]
      end
    end
  end
end
