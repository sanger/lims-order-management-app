ENV["LIMS_ORDER_MANAGEMENT_ENV"] = "development" unless ENV["LIMS_ORDER_MANAGEMENT_ENV"]

require 'yaml'
require 'lims-order-management-app'
require 'logging'

module Lims
  module OrderManagementApp
    env = ENV["LIMS_ORDER_MANAGEMENT_ENV"]
    amqp_settings = YAML.load_file(File.join('config','amqp.yml'))[env]
    api_settings = YAML.load_file(File.join('config','api.yml'))[env]
    order_settings = YAML.load_file(File.join('config','order.yml'))[env]

    creator = SampleConsumer.new(order_settings, amqp_settings, api_settings)
    creator.set_logger(Logging::LOGGER)

    Logging::LOGGER.info("Order Creator started")
    creator.start
    Logging::LOGGER.info("Order Creator stopped")
  end
end
