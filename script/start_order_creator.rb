require 'yaml'
require 'lims-order-management-app'
require 'logging'

module Lims
  module OrderManagementApp
    amqp_settings = YAML.load_file(File.join('config','amqp.yml'))["production"] 
    api_settings = YAML.load_file(File.join('config','api.yml'))["production"]

    creator = SampleConsumer.new(amqp_settings, api_settings)
    creator.set_logger(Logging::LOGGER)

    Logging::LOGGER.info("Order Creator started")
    creator.start
    Logging::LOGGER.info("Order Creator stopped")
  end
end
