require 'lims-order-management-app/spec_helper'
require 'lims-order-management-app/rule_matcher'
require 'lims-management-app/sample/sample'

module Lims::OrderManagementApp
  describe RuleMatcher do
    let(:matcher) {
      Class.new { include RuleMatcher }.new.tap do |rule_matcher|
        rule_matcher.initialize_rules(ruleset)
      end
    }

    let(:ruleset) {
      { "rules" =>
        [
          [{"samples.extraction.manual_dna_and_rna.input_tube_nap"=>
            {"cellular_material.extraction_process"=>"DNA & RNA Manual"}
          }],
          [{"samples.extraction.qiacube_dna_and_rna.input_tube_nap"=>
            {"cellular_material.extraction_process"=>"DNA & RNA QIAcube"}
          }],
          [{"samples.extraction.manual_dna_and_rna.input_tube_nap"=>
           {"cellular_material.extraction_process"=>"DNA & RNA Manual", "cellular_material.lysed"=>false},
          }],
          [{"samples.extraction.qiacube_dna_and_rna.input_tube_nap"=>
             {"cellular_material.extraction_process"=>"RNA QIAcube"}
          }]
        ]
      }
    }

    context "rule matched" do
      let(:samples_to_roles) { {
        'DNA & RNA Manual'  => 'samples.extraction.manual_dna_and_rna.input_tube_nap',
        'DNA & RNA QIAcube' => 'samples.extraction.qiacube_dna_and_rna.input_tube_nap'
      } }

      it "returns the correct pipeline" do
        samples_to_roles.each do |process, role|
          matcher.matching_rule({ :cellular_material => { :extraction_process => process } }).should == role
        end
      end
    end

    context "no rule matched" do
      let(:sample) { Lims::ManagementApp::Sample.new(
        { :sample_type        => "RNA",
          :cellular_material  => {:lysed => false, :extraction_process => "DNA & RNA Extraction"}
        })
      }
      it "raises an exception" do
        expect do
          matcher.matching_rule(sample)
        end.to raise_error(RuleMatcher::NoMatchingRule)
      end
    end
  end
end
