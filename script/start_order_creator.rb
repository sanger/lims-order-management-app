require 'yaml'
require 'lims-order-management-app'
require 'logging'
require 'lims-exception-notifier-app/exception_notifier'

module Lims
  module OrderManagementApp
    env = ENV["LIMS_ORDER_MANAGEMENT_APP_ENV"] or raise "LIMS_ORDER_MANAGEMENT_APP_ENV is not set in the environment"

    amqp_settings = YAML.load_file(File.join('config','amqp.yml'))[env]
    api_settings = YAML.load_file(File.join('config','api.yml'))[env]
    order_settings = YAML.load_file(File.join('config','order.yml'))[env]
    rule_settings = YAML.load_file(File.join('config','rules.yml'))

    notifier = Lims::ExceptionNotifierApp::ExceptionNotifier.new

    begin
      creator = SampleConsumer.new(order_settings, amqp_settings, api_settings, rule_settings)
      creator.set_logger(Logging::LOGGER)

      Logging::LOGGER.info("Order Creator started")

      notifier.notify do
        creator.start
      end
    rescue StandardError, LoadError, SyntaxError => e
      # log the caught exception
      notifier.send_notification_email(e)
    end

    Logging::LOGGER.info("Order Creator stopped")
  end
end
