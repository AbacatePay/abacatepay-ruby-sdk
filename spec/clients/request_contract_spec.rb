# frozen_string_literal: true

# The other client specs inject a hand-built Faraday connection, so they never
# exercise Client#build_client, the code that decides the real URL, the auth
# header and the timeout. A wrong endpoint path would leave every one of them
# green while the SDK 404s against the live API.
#
# These examples let the client build its own connection and only swap the
# adapter, so the request that would go over the wire is asserted directly.
RSpec.describe "Client request contract" do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:connection_options) { {} }

  before do
    AbacatePay.configure do |config|
      config.api_token = "test_api_token_123"
      config.timeout = 11
    end

    allow(Faraday).to receive(:new).and_wrap_original do |original, **options|
      connection_options.replace(options)
      original.call(**options) { |builder| builder.adapter :test, stubs }
    end
  end

  after { stubs.verify_stubbed_calls }

  def json_response(data)
    [200, { "Content-Type" => "application/json" }, { "data" => data }.to_json]
  end

  # ── Connection construction ───────────────────────────────────────────────

  describe "connection" do
    before do
      stubs.get("/v2/customers/list") { json_response([]) }
      AbacatePay.customers.list
    end

    it "sends the bearer token" do
      expect(connection_options[:headers]["Authorization"]).to eq("Bearer test_api_token_123")
    end

    it "sends a JSON content type" do
      expect(connection_options[:headers]["Content-Type"]).to eq("application/json")
    end

    it "applies the configured timeout" do
      expect(connection_options[:request][:timeout]).to eq(11)
    end

    it "applies the configured open timeout" do
      expect(connection_options[:request][:open_timeout]).to eq(11)
    end
  end

  # ── Endpoint paths ────────────────────────────────────────────────────────
  #
  # One entry per client. If a URI constant drifts from the real API, exactly
  # this list fails.

  {
    "customers" => [:customers, "/v2/customers/list"],
    "products" => [:products, "/v2/products/list"],
    "coupons" => [:coupons, "/v2/coupons/list"],
    "checkouts" => [:checkouts, "/v2/checkouts/list"],
    "subscriptions" => [:subscriptions, "/v2/subscriptions/list"],
    "transparents" => [:transparents, "/v2/transparents/list"],
    "payouts" => [:payouts, "/v2/payouts/list"],
    "pix" => [:pix, "/v2/pix/list"]
  }.each do |label, (accessor, path)|
    it "sends ##{label} list requests to #{path}" do
      requested = nil
      stubs.get(path) do |env|
        requested = env.url.path
        json_response([])
      end

      AbacatePay.public_send(accessor).list

      expect(requested).to eq(path)
    end
  end

  it "sends store requests to the un-prefixed store path" do
    requested = nil
    stubs.get("/v2/store/get") do |env|
      requested = env.url.path
      json_response({ "id" => "store-1" })
    end

    AbacatePay.store.get

    expect(requested).to eq("/v2/store/get")
  end

  # ── API base path ─────────────────────────────────────────────────────────
  #
  # The SDK used to derive v1/v2 from the token prefix and fell back to v1 for
  # anything unrecognised, while still sending v2-shaped paths. v1 uses a
  # different dialect (`/v1/billing/`, `/v1/customer/`, `pixQrCode`), so 10 of
  # the 12 paths this SDK calls do not exist there and every such call 404'd.
  # There is one base path now.

  %w[abc_live_token abc_dev_token legacy_token_format a].each do |token|
    it "routes #{token.inspect} to the v2 base path" do
      AbacatePay.configure { |config| config.api_token = token }
      requested = nil
      stubs.get("/v2/customers/list") do |env|
        requested = env.url.path
        json_response([])
      end

      AbacatePay.customers.list

      expect(requested).to eq("/v2/customers/list")
    end
  end

  # ── Unconfigured usage ────────────────────────────────────────────────────

  describe "when configure was never called" do
    before { AbacatePay.configuration = nil }

    it "raises ConfigurationError instead of a NoMethodError on nil" do
      expect { AbacatePay.customers.list }.to raise_error(AbacatePay::ConfigurationError)
    end

    it "names the call the developer is missing" do
      expect { AbacatePay.customers.list }
        .to raise_error(AbacatePay::ConfigurationError, /AbacatePay\.configure/)
    end
  end

  # Clearing the configuration must not leave a client behind that still holds
  # the previous credentials.
  describe "when the configuration is replaced after a client was built" do
    it "does not reuse the client built from the old configuration" do
      stubs.get("/v2/customers/list") { json_response([]) }
      AbacatePay.customers.list
      AbacatePay.configuration = nil

      expect { AbacatePay.customers.list }.to raise_error(AbacatePay::ConfigurationError)
    end
  end

  # ── Outgoing request bodies ───────────────────────────────────────────────
  #
  # Nothing else asserts what the SDK actually serialises, so the payload
  # builders were previously free to send anything at all.

  describe "customer creation payload" do
    let(:sent_body) do
      captured = nil
      stubs.post("/v2/customers/create") do |env|
        captured = JSON.parse(env.request_body)
        json_response({ "id" => "cust-1" })
      end

      customer = AbacatePay::Resources::Customers.new(
        "metadata" => { "name" => "Ana", "email" => "ana@example.com",
                        "cellphone" => "11999999999", "taxId" => "123.456.789-00" }
      )
      AbacatePay.customers.create(customer)
      captured
    end

    it "sends the customer name" do
      expect(sent_body["name"]).to eq("Ana")
    end

    it "sends the customer email" do
      expect(sent_body["email"]).to eq("ana@example.com")
    end

    it "camelCases the tax id for the API" do
      expect(sent_body["taxId"]).to eq("123.456.789-00")
    end
  end

  describe "checkout creation payload" do
    let(:sent_body) do
      captured = nil
      stubs.post("/v2/checkouts/create") do |env|
        captured = JSON.parse(env.request_body)
        json_response({ "id" => "chk-1" })
      end

      checkout = AbacatePay::Resources::Checkouts.new(
        "frequency" => "ONE_TIME", "methods" => ["PIX"]
      )
      product = AbacatePay::Resources::Billings::Product.new(
        "externalId" => "prod-1", "quantity" => 2
      )
      checkout.instance_variable_set(:@products, [product])
      checkout.instance_variable_set(
        :@customer, AbacatePay::Resources::Customers.new("id" => "cust-1")
      )
      AbacatePay.checkouts.create(checkout)
      captured
    end

    it "sends the frequency" do
      expect(sent_body["frequency"]).to eq("ONE_TIME")
    end

    it "references an existing customer by id" do
      expect(sent_body["customerId"]).to eq("cust-1")
    end

    it "sends line items with the product external id" do
      expect(sent_body["items"]).to eq([{ "id" => "prod-1", "quantity" => 2 }])
    end

    it "omits keys with no value rather than sending nulls" do
      expect(sent_body).not_to have_key("externalId")
    end
  end

  describe "checkout creation without a saved customer" do
    it "omits customerId when the customer has no id" do
      captured = nil
      stubs.post("/v2/checkouts/create") do |env|
        captured = JSON.parse(env.request_body)
        json_response({ "id" => "chk-2" })
      end

      checkout = AbacatePay::Resources::Checkouts.new("frequency" => "ONE_TIME")
      AbacatePay.checkouts.create(checkout)

      expect(captured).not_to have_key("customerId")
    end
  end
end
