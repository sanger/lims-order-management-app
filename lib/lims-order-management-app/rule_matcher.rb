module Lims::OrderManagementApp
  module RuleMatcher
   
    NoMatchingRule = Class.new(StandardError)

    def initialize_rules(rule_settings)
      @ruleset = rule_settings["rules"]
    end

    # @param [Lims::ManagementApp::Sample] sample
    # @return [String]
    def matching_rule(sample)
      @ruleset.each do |ruleset_items|
        ruleset_items.each do |rules|
          role = rules.keys.first
          rule_items = rules.values[0]
          return role if rule_items.all? do |key, value|
            value_from_sample = key.split('.').inject(sample) { |v,f| v && v[f.to_sym] }
            value_from_sample == value
          end
        end
      end

      raise NoMatchingRule
    end
  end
end
