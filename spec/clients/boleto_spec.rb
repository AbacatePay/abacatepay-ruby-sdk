# frozen_string_literal: true

# BOLETO is a first-class method in the v2 API — more prominent than CARD in
# the reference — and the SDK rejected it outright until 1.1.0.
RSpec.describe "Boleto support" do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }

  def payer
    customer = AbacatePay::Resources::Customers.new({})
    metadata = AbacatePay::Resources::Customers::Metadata.new({})
    metadata.name = "Mariana Costa"
    metadata.tax_id = "987.654.321-00"
    customer.instance_variable_set(:@metadata, metadata)
    customer
  end

  describe "hosted checkout" do
    let(:client) do
      connection = Faraday.new(url: "#{AbacatePay.configuration.api_url}/checkouts/") do |f|
        f.adapter :test, stubs
      end
      AbacatePay::Clients::CheckoutClient.new(connection)
    end
    let(:sent_body) { {} }

    before do
      stubs.post("/v2/checkouts/create") do |env|
        sent_body.replace(JSON.parse(env.request_body))
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "bill_1", "url" => "https://pay/bill_1" } }.to_json]
      end
    end

    it "accepts BOLETO as a payment method" do
      checkout = AbacatePay::Resources::Checkouts.new(methods: ["BOLETO"])
      client.create(checkout)

      expect(sent_body["methods"]).to eq(["BOLETO"])
    end

    it "sends the due date" do
      checkout = AbacatePay::Resources::Checkouts.new(methods: ["BOLETO"], due_date: "2026-08-15")
      client.create(checkout)

      expect(sent_body["dueDate"]).to eq("2026-08-15")
    end

    it "sends late-payment interest" do
      checkout = AbacatePay::Resources::Checkouts.new(methods: ["BOLETO"], interest: { value: 100 })
      client.create(checkout)

      expect(sent_body["interest"]).to eq({ "value" => 100 })
    end

    it "sends a percentage fine" do
      checkout = AbacatePay::Resources::Checkouts.new(
        methods: ["BOLETO"], fine: { value: 200, type: "PERCENTAGE" }
      )
      client.create(checkout)

      expect(sent_body["fine"]).to eq({ "value" => 200, "type" => "PERCENTAGE" })
    end

    it "omits boleto fields when they were not set" do
      client.create(AbacatePay::Resources::Checkouts.new(methods: ["PIX"]))

      expect(sent_body.keys).not_to include("dueDate", "interest", "fine")
    end

    it "nests the instalment cap under card" do
      checkout = AbacatePay::Resources::Checkouts.new(methods: ["CARD"], max_installments: 12)
      client.create(checkout)

      expect(sent_body["card"]).to eq({ "maxInstallments" => 12 })
    end

    it "sends the order bump product" do
      checkout = AbacatePay::Resources::Checkouts.new(methods: ["PIX"], up_sell_product_id: "prod_bump")
      client.create(checkout)

      expect(sent_body["upSellProductId"]).to eq("prod_bump")
    end

    it "sends merchant metadata" do
      checkout = AbacatePay::Resources::Checkouts.new(methods: ["PIX"], custom_metadata: { origem: "app" })
      client.create(checkout)

      expect(sent_body["metadata"]).to eq({ "origem" => "app" })
    end
  end

  describe "transparent checkout" do
    let(:client) do
      connection = Faraday.new(url: "#{AbacatePay.configuration.api_url}/transparents/") do |f|
        f.adapter :test, stubs
      end
      AbacatePay::Clients::TransparentClient.new(connection)
    end
    let(:sent_body) { {} }

    before do
      stubs.post("/v2/transparents/create") do |env|
        sent_body.replace(JSON.parse(env.request_body))
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "char_1", "barCode" => "34191...", "url" => "https://pay/boleto" } }.to_json]
      end
    end

    it "defaults to PIX" do
      client.create(AbacatePay::Resources::Transparents.new(amount: 1000))

      expect(sent_body["method"]).to eq("PIX")
    end

    it "sends BOLETO when asked" do
      charge = AbacatePay::Resources::Transparents.new(amount: 25_000)
      charge.instance_variable_set(:@customer, payer)
      client.create(charge, method: "BOLETO")

      expect(sent_body["method"]).to eq("BOLETO")
    end

    it "nests the payer under data" do
      charge = AbacatePay::Resources::Transparents.new(amount: 25_000)
      charge.instance_variable_set(:@customer, payer)
      client.create(charge, method: "BOLETO")

      expect(sent_body["data"]["customer"]["taxId"]).to eq("987.654.321-00")
    end

    it "sends the boleto due date under data" do
      charge = AbacatePay::Resources::Transparents.new(amount: 25_000, due_date: "2026-08-15")
      charge.instance_variable_set(:@customer, payer)
      client.create(charge, method: "BOLETO")

      expect(sent_body["data"]["dueDate"]).to eq("2026-08-15")
    end

    it "maps the digitable line from the response" do
      charge = AbacatePay::Resources::Transparents.new(amount: 25_000)
      charge.instance_variable_set(:@customer, payer)

      expect(client.create(charge, method: "BOLETO").bar_code).to eq("34191...")
    end

    # The API returns a generic 422; naming the field costs one round trip less.
    it "refuses a boleto without the payer name and taxId" do
      expect do
        client.create(AbacatePay::Resources::Transparents.new(amount: 100), method: "BOLETO")
      end.to raise_error(ArgumentError, /BOLETO requires .*name.*tax_id/)
    end

    it "refuses an unsupported transparent method" do
      expect do
        client.create(AbacatePay::Resources::Transparents.new(amount: 100), method: "CARD")
      end.to raise_error(ArgumentError, /supports PIX and BOLETO/)
    end
  end
end
