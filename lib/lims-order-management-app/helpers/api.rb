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

        def post(url, parameters)
          response = RestClient.post(url, parameters.to_json, HEADERS)
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
