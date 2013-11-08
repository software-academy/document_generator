require 'simplecov'
require 'json'

SimpleCov.start do
  add_filter '/spec/'
end

require 'rspec'
require 'rspec/fire'

require 'document_generator'

RSpec.configure do |config|
  config.include(RSpec::Fire)

  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run focused: true
  config.alias_example_to :fit, focused: true
  config.alias_example_to :pit, pending: true
  config.run_all_when_everything_filtered = true
end
