module Lims::OrderManagementApp
  module RuleMatcher
   
    NoMatchingRule = Class.new(StandardError)

    RULES = [
      [ { 'cellular_material.extraction_process' => 'DNA & RNA Manual' },  'samples.extraction.manual_dna_and_rna.input_tube_nap'  ],
      [ { 'cellular_material.extraction_process' => 'DNA & RNA QIAcube' }, 'samples.extraction.qiacube_dna_and_rna.input_tube_nap' ]
    ]

    # @param [Lims::ManagementApp::Sample] sample
    # @return [String]
    def matching_rule(sample)
      RULES.each do |(rule,role)|
        return role if rule.all? do |key, value|
          value_from_sample = key.split('.').inject(sample) { |v,f| v && v[f.to_sym] }
          value_from_sample == value
        end
      end

      raise NoMatchingRule
    end
  end
end
