# frozen_string_literal: true

require "stringio"

RSpec.describe AbacatePay::Configuration do
  subject(:configuration) { described_class.new }

  # The deprecation notice is expected output, not a test failure, capture it
  # rather than stubbing a method on the object under test.
  def silence_stderr
    original = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original
  end

  # The SDK used to derive the API version from the token prefix and fall back
  # to v1 for anything it did not recognise, while still sending v2-shaped
  # paths. v1 exists but speaks a different dialect, so those paths 404'd:
  # /v1/customers/list is Not found, while the real v1 route is
  # /v1/customer/list. The fallback broke every call for older token formats.
  describe "#api_url" do
    ["abc_live_token", "abc_dev_token", "legacy_token_format", "", nil].each do |token|
      it "resolves to the v2 base URL for #{token.inspect}" do
        configuration.api_token = token
        expect(configuration.api_url).to eq("https://api.abacatepay.com/v2")
      end
    end

    it "never resolves to the v1 prefix this SDK does not speak" do
      configuration.api_token = "anything_at_all"
      expect(configuration.api_url).not_to include("/v1")
    end
  end

  describe "#validate!" do
    it "rejects a nil token" do
      expect { configuration.validate! }
        .to raise_error(AbacatePay::ConfigurationError, /API token is required/)
    end

    it "rejects an empty token" do
      configuration.api_token = ""
      expect { configuration.validate! }
        .to raise_error(AbacatePay::ConfigurationError, /must not be empty/)
    end

    it "rejects a whitespace-only token" do
      configuration.api_token = "   "
      expect { configuration.validate! }
        .to raise_error(AbacatePay::ConfigurationError, /must not be empty/)
    end

    it "accepts any non-empty token" do
      configuration.api_token = "tok_123"
      expect { configuration.validate! }.not_to raise_error
    end

    # The environment is decided by the API key itself, so the SDK must not
    # reject a value it has no business interpreting.
    it "no longer rejects an unknown environment" do
      configuration.api_token = "tok_123"
      silence_stderr { configuration.environment = :whatever }

      expect { configuration.validate! }.not_to raise_error
    end
  end

  describe "#environment" do
    it "warns that it has no effect" do
      output = silence_stderr { configuration.environment = :production }

      expect(output).to include("no effect")
    end

    it "does not influence the base URL" do
      configuration.api_token = "tok_123"
      silence_stderr { configuration.environment = :production }

      expect(configuration.api_url).to eq("https://api.abacatepay.com/v2")
    end
  end

  describe "#timeout" do
    it "defaults to 30 seconds" do
      expect(configuration.timeout).to eq(30)
    end
  end
end
