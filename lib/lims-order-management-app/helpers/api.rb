require 'rest_client'
require 'json'

module Lims::OrderManagementApp
  module Helpers
    module API

      HEADERS = {'Content-Type' => 'application/json', 'Accept' => 'application/json'}

      module Request
        def get(url)
          RestClient.get(url, HEADERS)
        end

        def post(url, parameters)
          RestClient.post(url, parameters.to_json, HEADERS)
        end
      end
      include Request

      def self.included(klass)
        klass.class_eval do
          attribute :root_url, String, :required => true, :writer => :private, :reader => :private
          attribute :root, String, :required => true, :writer => :private, :reader => :private
        end
      end

      def initialize_api
        root = JSON.parse(get(root_url))        
      end

      def url_for(model, action)
        root[model.to_s]["actions"][action.to_s]
      end
    end
  end
end
