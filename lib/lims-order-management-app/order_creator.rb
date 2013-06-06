require 'common'
require 'lims-order-management-app/helpers/api'
require 'rubygems'
require 'ruby-debug/debugger'

module Lims::OrderManagementApp
  class OrderCreator
    include Virtus
    include Aequitas
    include Helpers::API

    def initialize(api_settings)
      @root_url = api_settings["url"]      
      initialize_api
    end

    def execute(sample, pipeline)

    end
  end
end
