# frozen_string_literal: true

require "stringio"

RSpec.describe AbacatePay::Resources::Billings do
  # Unknown enum values pass through with a warning instead of raising, so the
  # SDK does not break when AbacatePay introduces a value.
  def silence_stderr
    original = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original
  end
  # ── flat attributes ───────────────────────────────────────────────────────────

  describe "#initialize with flat attributes" do
    subject(:billing) do
      described_class.new(
        "id" => "bill-123",
        "accountId" => "acc-456",
        "url" => "https://pay.abacatepay.com/bill-123",
        "devMode" => true,
        "amount" => 5000
      )
    end

    it "sets id" do
      expect(billing.id).to eq("bill-123")
    end

    it "sets account_id from accountId" do
      expect(billing.account_id).to eq("acc-456")
    end

    it "sets url" do
      expect(billing.url).to eq("https://pay.abacatepay.com/bill-123")
    end

    it "sets amount" do
      expect(billing.amount).to eq(5000)
    end

    it "reflects dev_mode correctly" do
      expect(billing.dev_mode).to be true
    end
  end

  # ── dev_mode? predicate ───────────────────────────────────────────────────────

  describe "#dev_mode?" do
    it "returns true when devMode is true" do
      billing = described_class.new("devMode" => true)
      expect(billing.dev_mode?).to be true
    end

    it "returns false when devMode is false" do
      billing = described_class.new("devMode" => false)
      expect(billing.dev_mode?).to be false
    end

    it "returns nil when devMode is absent" do
      billing = described_class.new({})
      expect(billing.dev_mode?).to be_nil
    end
  end

  # ── enum attributes ───────────────────────────────────────────────────────────

  describe "#initialize with enum attributes" do
    it "sets frequency from a valid value" do
      billing = described_class.new("frequency" => "ONE_TIME")
      expect(billing.frequency).to eq("ONE_TIME")
    end

    it "sets status from a valid value" do
      billing = described_class.new("status" => "PENDING")
      expect(billing.status).to eq("PENDING")
    end

    it "sets methods from an array of valid values" do
      billing = described_class.new("methods" => ["PIX"])
      expect(billing.methods).to eq(["PIX"])
    end

    # Unknown values pass through with a warning: rejecting them would break
    # parsing every time AbacatePay introduces a value.
    it "passes an unknown frequency through" do
      expect { silence_stderr { described_class.new("frequency" => "YEARLY") } }.not_to raise_error
    end

    it "passes an unknown status through" do
      expect { silence_stderr { described_class.new("status" => "UNKNOWN") } }.not_to raise_error
    end

    it "passes an unknown payment method through" do
      expect { silence_stderr { described_class.new("methods" => ["CASH"]) } }.not_to raise_error
    end
  end

  # ── datetime attributes ───────────────────────────────────────────────────────

  describe "#initialize with datetime attributes" do
    subject(:billing) do
      described_class.new(
        "createdAt" => "2024-03-10T14:00:00Z",
        "updatedAt" => "2024-03-11T08:30:00Z",
        "nextBilling" => "2024-04-10T14:00:00Z"
      )
    end

    it "parses created_at as a DateTime" do
      expect(billing.created_at).to be_a(DateTime)
      expect(billing.created_at.year).to eq(2024)
      expect(billing.created_at.month).to eq(3)
    end

    it "parses updated_at as a DateTime" do
      expect(billing.updated_at).to be_a(DateTime)
      expect(billing.updated_at.day).to eq(11)
    end

    it "parses next_billing as a DateTime" do
      expect(billing.next_billing).to be_a(DateTime)
      expect(billing.next_billing.month).to eq(4)
    end
  end

  # ── nested products ───────────────────────────────────────────────────────────

  describe "#initialize with nested products" do
    subject(:billing) do
      described_class.new(
        "products" => [
          { "externalId" => "ext-1", "name" => "Item A", "quantity" => 2, "price" => 800 },
          { "externalId" => "ext-2", "name" => "Item B", "quantity" => 1, "price" => 1200 }
        ]
      )
    end

    it "sets products as an array" do
      expect(billing.products).to be_an(Array)
      expect(billing.products.size).to eq(2)
    end

    it "builds each product as a Billings::Product" do
      expect(billing.products.first).to be_a(AbacatePay::Resources::Billings::Product)
    end

    it "maps product attributes correctly" do
      expect(billing.products.first.external_id).to eq("ext-1")
      expect(billing.products.first.name).to eq("Item A")
      expect(billing.products.last.price).to eq(1200)
    end
  end

  # ── nested metadata ───────────────────────────────────────────────────────────

  describe "#initialize with nested metadata" do
    subject(:billing) do
      described_class.new(
        "metadata" => {
          "fee" => 100,
          "returnUrl" => "https://example.com/cancel",
          "completionUrl" => "https://example.com/done"
        }
      )
    end

    it "sets metadata as a Billings::Metadata instance" do
      expect(billing.metadata).to be_a(AbacatePay::Resources::Billings::Metadata)
    end

    it "maps metadata attributes correctly" do
      expect(billing.metadata.fee).to eq(100)
      expect(billing.metadata.return_url).to eq("https://example.com/cancel")
      expect(billing.metadata.completion_url).to eq("https://example.com/done")
    end
  end

  # ── nested customer ───────────────────────────────────────────────────────────

  describe "#initialize with nested customer" do
    subject(:billing) do
      described_class.new(
        "customer" => { "id" => "cust-999" }
      )
    end

    it "sets customer as a Customers instance" do
      expect(billing.customer).to be_a(AbacatePay::Resources::Customers)
    end

    it "maps the customer id correctly" do
      expect(billing.customer.id).to eq("cust-999")
    end
  end

  # ── empty data ────────────────────────────────────────────────────────────────

  describe "#initialize with empty data" do
    subject(:billing) { described_class.new({}) }

    it "sets all attributes to nil" do
      expect(billing.id).to be_nil
      expect(billing.url).to be_nil
      expect(billing.amount).to be_nil
      expect(billing.frequency).to be_nil
      expect(billing.status).to be_nil
      expect(billing.products).to be_nil
      expect(billing.metadata).to be_nil
      expect(billing.customer).to be_nil
    end
  end
end
