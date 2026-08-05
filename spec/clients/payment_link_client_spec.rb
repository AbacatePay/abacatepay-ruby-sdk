# frozen_string_literal: true

RSpec.describe AbacatePay::Clients::PaymentLinkClient do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_client) do
    Faraday.new(url: "#{AbacatePay.configuration.api_url}/payment-links/") do |f|
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(faraday_client) }

  let(:link) do
    checkout = AbacatePay::Resources::Checkouts.new("methods" => ["PIX"], "externalId" => "campanha-1")
    product = AbacatePay::Resources::Billings::Product.new("externalId" => "prod-1", "quantity" => 1)
    checkout.instance_variable_set(:@products, [product])
    checkout
  end

  describe "#list" do
    before do
      stubs.get("/v2/payment-links/list") do
        [200, { "Content-Type" => "application/json" },
         { "data" => [{ "id" => "link-1", "url" => "https://pay.abacatepay.com/link-1" }] }.to_json]
      end
    end

    it "returns Checkouts resources" do
      expect(client.list.first).to be_a(AbacatePay::Resources::Checkouts)
    end

    it "maps the shareable url" do
      expect(client.list.first.url).to eq("https://pay.abacatepay.com/link-1")
    end
  end

  describe "#get" do
    before do
      stubs.get("/v2/payment-links/get") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "link-1" } }.to_json]
      end
    end

    it "maps the link id" do
      expect(client.get("link-1").id).to eq("link-1")
    end
  end

  describe "#create" do
    let(:sent_body) { {} }

    before do
      stubs.post("/v2/payment-links/create") do |env|
        sent_body.replace(JSON.parse(env.request_body))
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "link-new", "url" => "https://pay.abacatepay.com/link-new" } }.to_json]
      end
    end

    # The endpoint rejects any other frequency, so the SDK never lets the
    # caller send one.
    it "always sends MULTIPLE_PAYMENTS as the frequency" do
      client.create(link)
      expect(sent_body["frequency"]).to eq("MULTIPLE_PAYMENTS")
    end

    it "sends line items in the v2 shape" do
      client.create(link)
      expect(sent_body["items"]).to eq([{ "id" => "prod-1", "quantity" => 1 }])
    end

    it "sends the external id" do
      client.create(link)
      expect(sent_body["externalId"]).to eq("campanha-1")
    end

    it "returns the created link" do
      expect(client.create(link).url).to eq("https://pay.abacatepay.com/link-new")
    end
  end

  describe "#refund" do
    before do
      stubs.post("/v2/payment-links/refund") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "char-1", "status" => "REFUNDED" } }.to_json]
      end
    end

    it "returns the refunded charge" do
      expect(client.refund("char-1").status).to eq("REFUNDED")
    end
  end
end
