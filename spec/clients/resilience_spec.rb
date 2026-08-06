# frozen_string_literal: true

# The API reference tells integrators to back off on 429 and 5xx. The SDK did
# none of that, so a transient blip surfaced as ApiError inside a payment flow.
RSpec.describe "Request resilience" do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:connection_options) { {} }

  before do
    AbacatePay.configure do |config|
      config.api_token = "test_api_token_123"
      config.max_retries = 2
    end

    allow(Faraday).to receive(:new).and_wrap_original do |original, **options, &block|
      connection_options.replace(options)
      original.call(**options) do |builder|
        block&.call(builder)
        builder.adapter :test, stubs
      end
    end
  end

  def ok_response
    [200, { "Content-Type" => "application/json" }, { "data" => [] }.to_json]
  end

  describe "retry on transient failures" do
    it "retries a 429 and succeeds" do
      attempts = 0
      stubs.get("/v2/customers/list") do
        attempts += 1
        attempts < 2 ? [429, {}, ""] : ok_response
      end

      AbacatePay.customers.list

      expect(attempts).to eq(2)
    end

    it "retries a 503 and succeeds" do
      attempts = 0
      stubs.get("/v2/customers/list") do
        attempts += 1
        attempts < 3 ? [503, {}, ""] : ok_response
      end

      AbacatePay.customers.list

      expect(attempts).to eq(3)
    end

    it "gives up after max_retries and raises ApiError" do
      stubs.get("/v2/customers/list") { [503, {}, ""] }

      expect { AbacatePay.customers.list }.to raise_error(AbacatePay::ApiError)
    end

    it "does not retry a 4xx that is not rate limiting" do
      attempts = 0
      stubs.get("/v2/customers/list") do
        attempts += 1
        [422, {}, ""]
      end

      expect { AbacatePay.customers.list }.to raise_error(AbacatePay::ApiError)
      expect(attempts).to eq(1)
    end
  end

  # Repeating a create after a timeout could charge a customer twice, and the
  # API exposes no idempotency key that would make it safe.
  describe "writes are never retried" do
    it "sends a failing POST exactly once" do
      attempts = 0
      stubs.post("/v2/customers/create") do
        attempts += 1
        [503, {}, ""]
      end

      expect do
        AbacatePay.customers.create(AbacatePay::Resources::Customers.new({}))
      end.to raise_error(AbacatePay::ApiError)
      expect(attempts).to eq(1)
    end
  end

  describe "when retries are disabled" do
    before { AbacatePay.configure { |config| config.max_retries = 0 } }

    it "sends the request once" do
      attempts = 0
      stubs.get("/v2/customers/list") do
        attempts += 1
        [503, {}, ""]
      end

      expect { AbacatePay.customers.list }.to raise_error(AbacatePay::ApiError)
      expect(attempts).to eq(1)
    end
  end

  describe "malformed responses" do
    it "raises ApiError instead of leaking JSON::ParserError" do
      stubs.get("/v2/customers/list") { [200, { "Content-Type" => "application/json" }, "not json"] }

      expect { AbacatePay.customers.list }
        .to raise_error(AbacatePay::ApiError, /Malformed API response/)
    end

    # `webhooks/delete` answers {"success":true} with no data. Treating that as
    # malformed turned a working call into an error.
    # A list endpoint with no payload is an empty result, not an error.
    it "returns an empty list when a successful response carries no data" do
      stubs.get("/v2/customers/list") do
        [200, { "Content-Type" => "application/json" }, { "success" => true }.to_json]
      end

      expect(AbacatePay.customers.list).to eq([])
    end

    it "raises ApiError on an envelope that is neither data nor success" do
      stubs.get("/v2/customers/list") do
        [200, { "Content-Type" => "application/json" }, { "unexpected" => true }.to_json]
      end

      expect { AbacatePay.customers.list }
        .to raise_error(AbacatePay::ApiError, /Unexpected API response/)
    end
  end

  describe "request headers" do
    before do
      stubs.get("/v2/customers/list") { ok_response }
      AbacatePay.customers.list
    end

    # Lets AbacatePay attribute traffic and diagnose version-specific issues.
    it "identifies the SDK and Ruby version" do
      expect(connection_options[:headers]["User-Agent"])
        .to eq("abacatepay-ruby/#{AbacatePay::VERSION} ruby/#{RUBY_VERSION}")
    end
  end
end
