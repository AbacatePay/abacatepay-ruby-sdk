# frozen_string_literal: true

require "abacate_pay"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed

  config.before(:each) do
    AbacatePay.configure do |c|
      c.api_token = "test_api_token_123"
      c.environment = :sandbox
    end
  end

  config.after(:each) do
    AbacatePay.reset!
  end
end
