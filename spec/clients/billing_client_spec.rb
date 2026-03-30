# frozen_string_literal: true

RSpec.describe AbacatePay::Clients::BillingClient do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_client) do
    Faraday.new(url: "#{AbacatePay.configuration.api_url}/billing/") do |f|
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(faraday_client) }

  # ── list ──────────────────────────────────────────────────────────────────────

  describe "#list" do
    let(:billing_data) do
      [
        { "id" => "bill-1", "url" => "https://pay.example.com/1", "amount" => 1000, "devMode" => true },
        { "id" => "bill-2", "url" => "https://pay.example.com/2", "amount" => 2000, "devMode" => false }
      ]
    end

    before do
      stubs.get("/v1/billing/list") do
        [200, { "Content-Type" => "application/json" }, { "data" => billing_data }.to_json]
      end
    end

    it "returns an Array" do
      expect(client.list).to be_an(Array)
    end

    it "returns the correct number of billings" do
      expect(client.list.size).to eq(2)
    end

    it "returns Billings resource instances" do
      client.list.each do |billing|
        expect(billing).to be_a(AbacatePay::Resources::Billings)
      end
    end

    it "maps billing attributes correctly" do
      first = client.list.first
      expect(first.id).to eq("bill-1")
      expect(first.amount).to eq(1000)
      expect(first.dev_mode?).to be true
    end
  end

  describe "#list when the API returns an empty array" do
    before do
      stubs.get("/v1/billing/list") do
        [200, { "Content-Type" => "application/json" }, { "data" => [] }.to_json]
      end
    end

    it "returns an empty array" do
      expect(client.list).to eq([])
    end
  end

  describe "#list when the API returns an error" do
    before do
      stubs.get("/v1/billing/list") { raise Faraday::ConnectionFailed.new("timeout") }
    end

    it "raises ApiError" do
      expect { client.list }.to raise_error(AbacatePay::ApiError)
    end
  end

  # ── create ────────────────────────────────────────────────────────────────────

  describe "#create" do
    let(:response_data) do
      { "id" => "bill-new", "url" => "https://pay.example.com/new", "amount" => 3500, "devMode" => true }
    end

    before do
      stubs.post("/v1/billing/create") do
        [200, { "Content-Type" => "application/json" }, { "data" => response_data }.to_json]
      end
    end

    context "with a customer identified by id" do
      let(:customer) do
        AbacatePay::Resources::Customers.new("id" => "cust-111")
      end

      let(:billing_input) do
        billing = AbacatePay::Resources::Billings.new(
          "frequency" => "ONE_TIME",
          "methods" => ["PIX"]
        )
        # inject customer via instance variable to bypass protected setter
        billing.instance_variable_set(:@customer, customer)
        billing
      end

      it "returns a Billings resource" do
        expect(client.create(billing_input)).to be_a(AbacatePay::Resources::Billings)
      end

      it "maps the returned billing id" do
        result = client.create(billing_input)
        expect(result.id).to eq("bill-new")
      end

      it "maps the returned amount" do
        result = client.create(billing_input)
        expect(result.amount).to eq(3500)
      end
    end

    context "with a new inline customer" do
      let(:billing_input) do
        AbacatePay::Resources::Billings.new(
          "frequency" => "ONE_TIME",
          "methods" => ["PIX"]
        )
        # no customer → request_data[:customer] will have all-nil fields
      end

      it "returns a Billings resource without raising" do
        billing = AbacatePay::Resources::Billings.new(
          "frequency" => "ONE_TIME",
          "methods" => ["PIX"]
        )
        expect(client.create(billing)).to be_a(AbacatePay::Resources::Billings)
      end
    end
  end

  describe "#create when the API returns an error" do
    before do
      stubs.post("/v1/billing/create") { raise Faraday::ConnectionFailed.new("timeout") }
    end

    it "raises ApiError" do
      billing = AbacatePay::Resources::Billings.new("frequency" => "ONE_TIME", "methods" => ["PIX"])
      expect { client.create(billing) }.to raise_error(AbacatePay::ApiError)
    end
  end
end
