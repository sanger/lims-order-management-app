module Lims::OrderManagementApp
  module RuleMatcher
   
    NoMatchingRule = Class.new(StandardError)

    CELL_PELLET = "Cell Pellet"

    RULES = [
      {:sample_type => CELL_PELLET, :lysed => true}
    ]

    # @param [Lims::ManagementApp::Sample] sample
    # @return [String]
    def matching_rule(sample)
      RULES.each do |rule|
        if rule[:sample_type] == sample.sample_type &&
          rule[:lysed] = sample.cellular_material.lysed
          return sample.cellular_material.extraction_process
        end
      end

      raise NoMatchingRule
    end

  end
end
