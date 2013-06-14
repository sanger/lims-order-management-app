require 'lims-order-management-app/spec_helper'
require 'lims-order-management-app/rule_matcher'
require 'lims-management-app/sample/sample'

module Lims::OrderManagementApp
  describe RuleMatcher do
    let(:matcher) { Class.new { include RuleMatcher }.new }

    context "rule matched" do
      let(:sample) { Lims::ManagementApp::Sample.new(
        { :sample_type        => "Cell Pellet",
          :cellular_material  => {:lysed => true, :extraction_process => "DNA & RNA Extraction"}
        })
      }
      it "returns the correct pipeline" do
        matcher.matching_rule(sample).should == sample.cellular_material.extraction_process
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
