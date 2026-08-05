# frozen_string_literal: true

RSpec.describe AbacatePay::Clients::WebhookClient do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_client) do
    Faraday.new(url: "#{AbacatePay.configuration.api_url}/webhooks/") do |f|
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(faraday_client) }

  describe "#list" do
    before do
      stubs.get("/v2/webhooks/list") do
        [200, { "Content-Type" => "application/json" },
         { "data" => [{ "id" => "wh-1", "name" => "Payments", "active" => true }] }.to_json]
      end
    end

    it "returns WebhookEndpoints resources" do
      expect(client.list.first).to be_a(AbacatePay::Resources::WebhookEndpoints)
    end

    it "maps the webhook name" do
      expect(client.list.first.name).to eq("Payments")
    end
  end

  describe "#get" do
    before do
      stubs.get("/v2/webhooks/get") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "wh-1", "endpoint" => "https://site.com/hook",
                       "events" => ["checkout.completed"], "createdAt" => "2026-08-04T10:00:00Z" } }.to_json]
      end
    end

    it "maps the endpoint" do
      expect(client.get("wh-1").endpoint).to eq("https://site.com/hook")
    end

    it "maps the subscribed events" do
      expect(client.get("wh-1").events).to eq(["checkout.completed"])
    end

    it "parses createdAt into a DateTime" do
      expect(client.get("wh-1").created_at).to be_a(DateTime)
    end
  end

  describe "#create" do
    let(:sent_body) { {} }

    before do
      stubs.post("/v2/webhooks/create") do |env|
        sent_body.replace(JSON.parse(env.request_body))
        [200, { "Content-Type" => "application/json" }, { "data" => { "id" => "wh-new" } }.to_json]
      end
    end

    it "returns the created webhook" do
      result = client.create(name: "Payments", endpoint: "https://site.com/hook",
                             secret: "s3cr3t", events: ["checkout.completed"])
      expect(result.id).to eq("wh-new")
    end

    it "sends every required field" do
      client.create(name: "Payments", endpoint: "https://site.com/hook",
                    secret: "s3cr3t", events: ["checkout.completed"])
      expect(sent_body.keys).to contain_exactly("name", "endpoint", "secret", "events")
    end

    it "wraps a single event into an array" do
      client.create(name: "P", endpoint: "https://site.com/hook",
                    secret: "s", events: "checkout.completed")
      expect(sent_body["events"]).to eq(["checkout.completed"])
    end

    # AbacatePay only delivers over HTTPS, failing locally beats a confusing
    # rejection after the round trip.
    it "rejects a plain HTTP endpoint" do
      expect do
        client.create(name: "P", endpoint: "http://site.com/hook", secret: "s", events: ["a"])
      end.to raise_error(ArgumentError, /HTTPS/)
    end

    it "rejects a malformed endpoint" do
      expect do
        client.create(name: "P", endpoint: "not a url", secret: "s", events: ["a"])
      end.to raise_error(ArgumentError, /HTTPS/)
    end

    it "rejects an empty event list" do
      expect do
        client.create(name: "P", endpoint: "https://site.com/hook", secret: "s", events: [])
      end.to raise_error(ArgumentError, /events must not be empty/)
    end
  end

  describe "#delete" do
    before do
      stubs.post("/v2/webhooks/delete") do
        [200, { "Content-Type" => "application/json" }, { "data" => { "id" => "wh-1" } }.to_json]
      end
    end

    it "returns the deleted webhook" do
      expect(client.delete("wh-1").id).to eq("wh-1")
    end
  end
end
