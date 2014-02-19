# Lims-order-management-app

Lims-order-management-app is responsible to create orders in S2 after sample creation. 
Every time a S2 sample is found to be in a published state, a new order is created in S2 following lims-order-management-app rules.

## Usage

Edit the configuration files under config/.

    bundle install
    export LIMS_ORDER_MANAGEMENT_APP_ENV="development"
    bundle exec ruby script/setup_rabbitmq_bindinds.rb -u user -p password -a http://localhost:15672/api/bindings/%2f/e/psd.s2/q/psd.s2.order-management
    bundle exec ruby script/start_order_creator.rb 

## Development

The following development notes apply from version 1.0.3.

Lims-order-management-app has a RabbitMQ queue as data source, which catch sample messages from S2.
Everytime a sample is found as published, it is considered to create a new order. 
The sample message payload should contain a correct "extraction\_process" field, which basically 
map a process name to an array of container uuids. For example:

    {"cellular_material": {"extraction_process": {"DNA & RNA Manual": ["11111111-2222-3333-4444-555555555555"]}}}

The above payload says that the sample goes through "DNA & RNA Manual" in the labware "11111111-2222-3333-4444-555555555555".
So the labware "11111111-2222-3333-4444-555555555555" will be used as an item of the order.
To create an order, we also need to associate a role to an item. Roles are defined in config/rules.yml.

For example, the following entry in rules.yml:

    "samples.extraction.manual_dna_and_rna.input_tube_nap":
      "cellular_material.extraction_process": "DNA & RNA Manual"

should be read like: if the sample has an extraction process name set to 'DNA & RNA Manual', the labware containing the sample
will have the role 'samples.extraction.manual\_dna\_and\_rna.input\_tube\_nap' in the order.
Following the above example, lims-order-management-app will finally send the following request to lims-laboratory-app to create the order:

    { "order": {
      "study_uuid": <study uuid defined in config/order.yml>,
      "pipeline": "Samples",
      "cost_code": "cost code",
      "sources": {
        "samples.extraction.manual_dna_and_rna.input_tube_nap": ["11111111-2222-3333-4444-555555555555"]
      }
    }}

The order is created with the user "s2-order-management-app" by default (see config/order.yml) and assumes that lims-laboratory-app
database contains a study with the uuid set in this configuration file.
