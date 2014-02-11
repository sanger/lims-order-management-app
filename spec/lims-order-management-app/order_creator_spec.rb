require 'lims-order-management-app/spec_helper'
require 'lims-order-management-app/order_creator'
require 'lims-management-app/sample/sample'

module Lims::OrderManagementApp
  describe OrderCreator do
    before do
      Lims::OrderManagementApp::OrderCreator.any_instance.stub(
        :initialize_api => nil,
        :ruleset => ruleset
      )
    end

    let(:ruleset) {
      { "rules" =>
        [
          [{"samples.extraction.manual_dna_and_rna.input_tube_nap"=>
            {"cellular_material.extraction_process"=>"DNA & RNA Manual"},
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

    let(:order_settings) { {
      "study_uuid" => "55555555-2222-3333-6666-777777777777",
      "cost_code" => "cost code",
      "input_tube_role" => "role"
    }}
    let(:creator) { described_class.new(order_settings, {}, ruleset).tap do |c|
      c.stub(:post) { |a| a }
      c.stub(:get) { mocked_containers }
    end
    }    
    let(:samples) {[
      {
        :sample => Lims::ManagementApp::Sample.new({
          :cellular_material => {:extraction_process => {'DNA & RNA Manual' => ["11111111-2222-3333-4444-666666666666"]}}
        }), 
        :uuid => '11111111-0000-0000-0000-111111111111'
      },
      {
        :sample => Lims::ManagementApp::Sample.new({
          :cellular_material => { :extraction_process => {'DNA & RNA QIAcube' => ["11111111-2222-3333-4444-777777777777", "11111111-2222-3333-4444-888888888888"]}}
        }), 
        :uuid => '11111111-0000-0000-0000-222222222222'
      }
    ]}

    context "valid context" do
      context "with samples contained in tubes" do
        let(:expected_order_parameters) { {
          :order => {
            :study_uuid => "55555555-2222-3333-6666-777777777777",
            :pipeline => 'Samples',
            :cost_code => "cost code",
            :sources => {
              'samples.extraction.manual_dna_and_rna.input_tube_nap'  => ['11111111-2222-3333-4444-666666666666'],
              'samples.extraction.qiacube_dna_and_rna.input_tube_nap' => ['11111111-2222-3333-4444-777777777777', '11111111-2222-3333-4444-888888888888']
            }
          }
        } }

        it "posts an order" do
          creator.should_receive(:post_order).with(expected_order_parameters)
          creator.create!(samples)
        end
      end

      context "with samples contained in 2 filter papers" do
        let(:expected_order_parameters) { {
          :order => {
            :study_uuid => "55555555-2222-3333-6666-777777777777",
            :pipeline => 'Samples',
            :cost_code => "cost code",
            :sources => {
              'samples.extraction.manual_dna_and_rna.input_tube_nap'  => ['11111111-2222-3333-4444-666666666666'],
              'samples.extraction.qiacube_dna_and_rna.input_tube_nap' => ['11111111-2222-3333-4444-777777777777', '11111111-2222-3333-4444-888888888888']
            }
          }
        } }

        it "posts an order" do
          creator.should_receive(:post_order).with(expected_order_parameters)
          creator.create!(samples)
        end
      end


      context "with samples contained in 1 filter paper" do
        let(:samples) {[
          {
            :sample => Lims::ManagementApp::Sample.new({
              :cellular_material => {:extraction_process => {'DNA & RNA Manual' => ['11111111-2222-3333-4444-666666666666']}}
            }), 
            :uuid => '11111111-0000-0000-0000-111111111111'
          },
          {
            :sample => Lims::ManagementApp::Sample.new({
              :cellular_material => {:extraction_process => {'DNA & RNA Manual' => ['11111111-2222-3333-4444-666666666666']}}
            }), 
            :uuid => '11111111-0000-0000-0000-222222222222'
          }
        ]}

        let(:expected_order_parameters) { {
          :order => {
            :study_uuid => "55555555-2222-3333-6666-777777777777",
            :pipeline => 'Samples',
            :cost_code => "cost code",
            :sources => {
              'samples.extraction.manual_dna_and_rna.input_tube_nap'  => [ '11111111-2222-3333-4444-666666666666']
            }
          }
        } }

        it "posts an order" do
          creator.should_receive(:post_order).with(expected_order_parameters)
          creator.create!(samples)
        end
      end
    end


    context "invalid context" do
      it "raises an error" do
        pending
        expect do
          creator.create!(samples)
        end.to raise_error(OrderCreator::SampleContainerNotFound)
      end
    end
  end
end
