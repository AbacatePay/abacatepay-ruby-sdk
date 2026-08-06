# frozen_string_literal: true

# Shapes and values the live API actually produces, captured while running the
# SDK against the sandbox. Each example here corresponds to a call that failed
# before the fix.
RSpec.describe "Live API conformance" do
  # Rejecting an unrecognised value while parsing a response turns every new
  # status AbacatePay introduces into a crash inside `list` and `get`, for
  # every integration at once. Unknown values pass through with a warning.
  describe "unknown enum values in responses" do
    def silence_stderr
      original = $stderr
      $stderr = StringIO.new
      yield
      $stderr.string
    ensure
      $stderr = original
    end

    it "does not raise on a status the SDK has never seen" do
      expect do
        silence_stderr { AbacatePay::Resources::Coupons.new("id" => "X", "status" => "SOMETHING_NEW") }
      end.not_to raise_error
    end

    it "keeps the value the API sent" do
      coupon = nil
      silence_stderr { coupon = AbacatePay::Resources::Coupons.new("id" => "X", "status" => "SOMETHING_NEW") }

      expect(coupon.status).to eq("SOMETHING_NEW")
    end

    it "warns so the gap is visible" do
      output = silence_stderr { AbacatePay::Resources::Coupons.new("id" => "X", "status" => "SOMETHING_NEW") }

      expect(output).to include("unknown Statuses value")
    end

    it "stays quiet for a known value" do
      output = silence_stderr { AbacatePay::Resources::Coupons.new("id" => "X", "status" => "ACTIVE") }

      expect(output).to be_empty
    end
  end

  describe "statuses the API returns" do
    it "accepts DISABLED, which a toggled-off coupon reports" do
      expect(AbacatePay::Enums::Coupons::Statuses.valid?("DISABLED")).to be true
    end

    it "accepts ACTIVE, which a payment link reports on creation" do
      expect(AbacatePay::Enums::Checkouts::Statuses.valid?("ACTIVE")).to be true
    end
  end

  # The API sends the coupon code as the object's `id` and the redemption
  # count as `redeemsCount`. The previous readers were always nil.
  describe "coupon field names" do
    subject(:coupon) do
      AbacatePay::Resources::Coupons.new(
        "id" => "SAVE20", "status" => "ACTIVE", "discount" => 20,
        "discountKind" => "PERCENTAGE", "maxRedeems" => 5, "redeemsCount" => 2,
        "notes" => "campanha", "devMode" => true
      )
    end

    it "reads the code from the id" do
      expect(coupon.code).to eq("SAVE20")
    end

    it "reads the redemption count" do
      expect(coupon.redeems_count).to eq(2)
    end

    it "keeps current_redeems answering for older code" do
      expect(coupon.current_redeems).to eq(2)
    end

    it "exposes notes" do
      expect(coupon.notes).to eq("campanha")
    end

    it "reports dev mode" do
      expect(coupon.dev_mode?).to be true
    end

    it "still prefers an explicit code when the API sends one" do
      explicit = AbacatePay::Resources::Coupons.new("id" => "abc", "code" => "EXPLICIT")

      expect(explicit.code).to eq("EXPLICIT")
    end
  end

  # `webhooks/delete` answers {"success":true,"error":null} with no data key.
  # Treating that as malformed turned a working call into an ApiError.
  describe "successful responses that carry no payload" do
    let(:stubs) { Faraday::Adapter::Test::Stubs.new }
    let(:client) do
      connection = Faraday.new(url: "#{AbacatePay.configuration.api_url}/webhooks/") do |f|
        f.adapter :test, stubs
      end
      AbacatePay::Clients::WebhookClient.new(connection)
    end

    let(:captured) { {} }

    def stub_delete(body)
      stubs.post("/v2/webhooks/delete") do |env|
        captured[:id] = env.params["id"]
        [200, { "Content-Type" => "application/json" }, body.to_json]
      end
    end

    it "does not raise" do
      stub_delete("success" => true, "error" => nil)

      expect { client.delete("webh_1") }.not_to raise_error
    end

    it "returns nil rather than an empty object" do
      stub_delete("success" => true, "error" => nil)

      expect(client.delete("webh_1")).to be_nil
    end

    it "sends the id in the query string, which is where the API reads it" do
      stub_delete("success" => true)

      client.delete("webh_42")

      expect(captured[:id]).to eq("webh_42")
    end

    it "still rejects an envelope that is neither data nor success" do
      stub_delete("unexpected" => true)

      expect { client.delete("webh_1") }.to raise_error(AbacatePay::ApiError, /Unexpected API response/)
    end
  end

  describe "webhook secret length" do
    let(:client) do
      stubs = Faraday::Adapter::Test::Stubs.new
      connection = Faraday.new(url: "#{AbacatePay.configuration.api_url}/webhooks/") do |f|
        f.adapter :test, stubs
      end
      AbacatePay::Clients::WebhookClient.new(connection)
    end

    # The API answers "Expected string length greater or equal to 32".
    it "refuses a secret the API would reject" do
      expect do
        client.create(name: "n", endpoint: "https://e.com/h", secret: "curto", events: ["checkout.completed"])
      end.to raise_error(ArgumentError, /at least 32 characters/)
    end
  end

  describe "resources built from an empty payload" do
    it "does not raise" do
      expect { AbacatePay::Resources::WebhookEndpoints.new(nil) }.not_to raise_error
    end
  end
end
