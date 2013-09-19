require 'lims-order-management-app/spec_helper'
require 'lims-order-management-app/order_creator'
require 'lims-management-app/sample/sample'

module Lims::OrderManagementApp
  describe OrderCreator do
    before do
      Lims::OrderManagementApp::OrderCreator.any_instance.stub(
        :initialize_api => nil,
        :url_for => mocked_search,
        :ruleset => ruleset
      )
    end

    let(:mocked_search) {
      {
        "search"=> {
          "actions"=> {
            "read"=> "http://example.org/11111111-2222-3333-4444-555555555555",
            "first"=> "http://example.org/11111111-2222-3333-4444-555555555555/page=1",
            "last"=> "http://example.org/11111111-2222-3333-4444-555555555555/page=-1"
          },
          "uuid"=> "11111111-2222-3333-4444-555555555555"
        }
      }
    }

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
      "user_uuid" => "66666666-2222-4444-9999-000000000000",
      "study_uuid" => "55555555-2222-3333-6666-777777777777",
      "cost_code" => "cost code",
      "input_tube_role" => "role"
    }}
    let(:creator) { described_class.new(order_settings, {}, ruleset).tap do |c|
      c.stub(:post) { |a| a }
      c.stub(:get) { mocked_tubes }
    end
    }    
    let(:samples) { [
      {:sample => Lims::ManagementApp::Sample.new(:cellular_material => { :extraction_process => 'DNA & RNA Manual'}), :uuid => '11111111-0000-0000-0000-111111111111'},
      {:sample => Lims::ManagementApp::Sample.new(:cellular_material => { :extraction_process => 'DNA & RNA QIAcube'}), :uuid => '11111111-0000-0000-0000-222222222222'}
    ] }

    context "valid context" do
      let(:mocked_tubes) {{
        "size"=> 2,
        "tubes"=> [
          {
            "uuid"=> "11111111-2222-3333-4444-666666666666",
            "aliquots"=> [{"sample"=> {"uuid"=> "11111111-0000-0000-0000-111111111111"}}]
          },
          {
            "uuid"=> "11111111-2222-3333-4444-888888888888",
            "aliquots"=> [{"sample"=> {"uuid"=> "11111111-0000-0000-0000-222222222222"}}]
          }
        ]
      }}

      let(:expected_order_parameters) { {
        :order => {
          :user_uuid => "66666666-2222-4444-9999-000000000000",
          :study_uuid => "55555555-2222-3333-6666-777777777777",
          :pipeline => 'Samples',
          :cost_code => "cost code",
          :sources => {
            'samples.extraction.manual_dna_and_rna.input_tube_nap'  => [ '11111111-2222-3333-4444-666666666666' ],
            'samples.extraction.qiacube_dna_and_rna.input_tube_nap' => [ '11111111-2222-3333-4444-888888888888' ]
          }
        }
      } }

      it "posts an order" do
        creator.should_receive(:post_order).with(expected_order_parameters)
        creator.execute(samples)
      end
    end


    context "invalid context" do
      let(:mocked_tubes) {{
        "size"=> 1,
        "tubes"=> [
          {
            "uuid"=> "11111111-2222-3333-4444-888888888888",
            "aliquots"=> [{"sample"=> {"uuid"=> "11111111-0000-0000-0000-222222222222"}}]
          }
        ]
      }}

      it "raises an error" do
        expect do
          creator.execute(samples)
        end.to raise_error(OrderCreator::TubeNotFound)
      end
    end
  end
end
