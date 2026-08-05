# frozen_string_literal: true

RSpec.describe AbacatePay::Clients::SubscriptionClient do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_client) do
    Faraday.new(url: "#{AbacatePay.configuration.api_url}/subscriptions/") do |f|
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(faraday_client) }
  let(:sent_body) { {} }

  describe "#change_plan" do
    before do
      stubs.post("/v2/subscriptions/change-plan") do |env|
        sent_body.replace(JSON.parse(env.request_body))
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "subu_1", "status" => "PENDING" } }.to_json]
      end
    end

    it "returns the pending update object" do
      result = client.change_plan("subs_1", product_id: "prod_pro")

      expect(result["status"]).to eq("PENDING")
    end

    it "sends the subscription id" do
      client.change_plan("subs_1", product_id: "prod_pro")

      expect(sent_body["id"]).to eq("subs_1")
    end

    it "sends the new product id" do
      client.change_plan("subs_1", product_id: "prod_pro")

      expect(sent_body["productId"]).to eq("prod_pro")
    end

    it "defaults quantity to 1" do
      client.change_plan("subs_1", product_id: "prod_pro")

      expect(sent_body["quantity"]).to eq(1)
    end

    it "sends an explicit quantity" do
      client.change_plan("subs_1", product_id: "prod_pro", quantity: 3)

      expect(sent_body["quantity"]).to eq(3)
    end

    # The API documents a minimum of 1; failing locally saves a round trip.
    it "rejects a quantity below 1" do
      expect { client.change_plan("subs_1", product_id: "prod_pro", quantity: 0) }
        .to raise_error(ArgumentError, /quantity must be at least 1/)
    end
  end

  describe "#record_usage" do
    before do
      stubs.post("/v2/subscriptions/record-usage") do |env|
        sent_body.replace(JSON.parse(env.request_body))
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "usage_1", "units" => 50 } }.to_json]
      end
    end

    it "returns the recorded usage" do
      expect(client.record_usage("subs_1", product_id: "prod_api", units: 50)["units"]).to eq(50)
    end

    it "defaults the action to add" do
      client.record_usage("subs_1", product_id: "prod_api", units: 50)

      expect(sent_body["action"]).to eq("add")
    end

    it "sends the units" do
      client.record_usage("subs_1", product_id: "prod_api", units: 50)

      expect(sent_body["units"]).to eq(50)
    end

    it "supports subtracting units" do
      client.record_usage("subs_1", product_id: "prod_api", units: 5, action: "subtract")

      expect(sent_body["action"]).to eq("subtract")
    end

    it "rejects units below 1" do
      expect { client.record_usage("subs_1", product_id: "prod_api", units: 0) }
        .to raise_error(ArgumentError, /units must be at least 1/)
    end

    it "rejects an unknown action" do
      expect { client.record_usage("subs_1", product_id: "prod_api", units: 1, action: "reset") }
        .to raise_error(ArgumentError, /action must be/)
    end
  end
end
