module Lims::OrderManagementApp
  module RuleMatcher
   
    NonMatchingRule = Class.new(StandardError)

    CELL_PELLET = "Cell Pellet"
    DNA_RNA_EXTRACTION = 'DNA & RNA Extraction'

    RULES = [
      {:sample_type => CELL_PELLET, :lysed => true} => DNA_RNA_EXTRACTION
    ]

    def matching_rule(sample)
      RULES.each do |rule|
        rule.each do |criteria, pipeline|
          if criteria[:sample_type] == sample.sample_type &&
            criteria[:lysed] = sample.cellular_material.lysed
            return pipeline
          end
        end
      end

      raise NonMatchingRule
    end

  end
end
