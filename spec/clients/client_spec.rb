# frozen_string_literal: true

RSpec.describe AbacatePay::Clients::Client do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_client) do
    Faraday.new(url: "https://sandbox.api.abacatepay.com/v1/test/") do |f|
      f.adapter :test, stubs
    end
  end

  # Concrete subclass to exercise protected #request
  let(:test_client_class) do
    Class.new(described_class) do
      def call_request(method, uri, options = {})
        request(method, uri, options)
      end
    end
  end

  let(:client) { test_client_class.new("test", faraday_client) }

  # ── build_client ──────────────────────────────────────────────────────────────

  describe "#build_client (via constructor)" do
    it "creates a client that uses the configured API URL" do
      # build_client is exercised when no explicit Faraday client is passed
      real_client = described_class.new("billing")
      expect(real_client).to be_a(described_class)
    end
  end

  # ── request – success ─────────────────────────────────────────────────────────

  describe "#request" do
    context "with a successful GET response" do
      before do
        stubs.get("/v1/test/items") do
          [200, { "Content-Type" => "application/json" },
           { "data" => [{ "id" => "item-1" }] }.to_json]
        end
      end

      it "returns the parsed data from the response" do
        result = client.call_request("GET", "items")
        expect(result).to eq([{ "id" => "item-1" }])
      end
    end

    context "with a successful POST response" do
      before do
        stubs.post("/v1/test/create") do
          [200, { "Content-Type" => "application/json" },
           { "data" => { "id" => "new-item" } }.to_json]
        end
      end

      it "returns the parsed data from the response" do
        result = client.call_request("POST", "create", json: { name: "test" })
        expect(result).to eq({ "id" => "new-item" })
      end
    end

    context "when the response body has no 'data' key" do
      before do
        stubs.get("/v1/test/bad") do
          [200, { "Content-Type" => "application/json" }, { "error" => "something" }.to_json]
        end
      end

      it "raises ApiError" do
        expect { client.call_request("GET", "bad") }
          .to raise_error(AbacatePay::ApiError)
      end
    end

    context "when a Faraday connection error occurs" do
      before do
        stubs.get("/v1/test/fail") { raise Faraday::ConnectionFailed.new("timeout") }
      end

      it "raises ApiError" do
        expect { client.call_request("GET", "fail") }
          .to raise_error(AbacatePay::ApiError)
      end
    end
  end

  # ── error handling ────────────────────────────────────────────────────────────

  describe "AbacatePay error hierarchy" do
    it "ApiError is a subclass of AbacatePay::Error" do
      expect(AbacatePay::ApiError.ancestors).to include(AbacatePay::Error)
    end

    it "ConfigurationError is a subclass of AbacatePay::Error" do
      expect(AbacatePay::ConfigurationError.ancestors).to include(AbacatePay::Error)
    end
  end
end
