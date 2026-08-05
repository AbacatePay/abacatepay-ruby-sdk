# frozen_string_literal: true

# simplecov has been a declared dependency since 0.1.0 without ever being
# loaded, so coverage was never actually measured. It must be required before
# the library so that every file is instrumented.
require "simplecov"

SimpleCov.start do
  add_filter "/spec/"
  add_group "Clients", "lib/abacate_pay/clients"
  add_group "Resources", "lib/abacate_pay/resources"
  add_group "Enums", "lib/abacate_pay/enums"
  add_group "Webhooks", "lib/abacate_pay/webhooks"

  # A published payments SDK should not regress below this.
  minimum_coverage line: 90
end

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

  config.before do
    AbacatePay.configure do |c|
      c.api_token = "test_api_token_123"
    end
  end

  config.after do
    AbacatePay.reset!
  end
end
