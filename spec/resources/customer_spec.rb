# frozen_string_literal: true

RSpec.describe AbacatePay::Resources::Customers do
  # ── flat attributes ───────────────────────────────────────────────────────────

  describe "#initialize with flat attributes" do
    subject(:customer) { described_class.new("id" => "cust-123") }

    it "sets id" do
      expect(customer.id).to eq("cust-123")
    end
  end

  # ── nested metadata ───────────────────────────────────────────────────────────

  describe "#initialize with nested metadata" do
    subject(:customer) do
      described_class.new(
        "id" => "cust-456",
        "metadata" => {
          "name" => "Ana Souza",
          "email" => "ana@example.com",
          "cellphone" => "+5521999990000",
          "taxId" => "111.222.333-44"
        }
      )
    end

    it "sets metadata as a Customers::Metadata instance" do
      expect(customer.metadata).to be_a(AbacatePay::Resources::Customers::Metadata)
    end

    it "maps name correctly" do
      expect(customer.metadata.name).to eq("Ana Souza")
    end

    it "maps email correctly" do
      expect(customer.metadata.email).to eq("ana@example.com")
    end

    it "maps cellphone correctly" do
      expect(customer.metadata.cellphone).to eq("+5521999990000")
    end

    it "maps tax_id from taxId" do
      expect(customer.metadata.tax_id).to eq("111.222.333-44")
    end
  end

  # ── empty data ────────────────────────────────────────────────────────────────

  describe "#initialize with empty data" do
    subject(:customer) { described_class.new({}) }

    it "sets id to nil" do
      expect(customer.id).to be_nil
    end

    it "sets metadata to nil" do
      expect(customer.metadata).to be_nil
    end
  end

  # ── nil nested value ──────────────────────────────────────────────────────────

  describe "#initialize when metadata key is present but nil" do
    subject(:customer) { described_class.new("id" => "cust-789", "metadata" => nil) }

    it "sets metadata to nil" do
      expect(customer.metadata).to be_nil
    end
  end

  # The API returns the customer fields at the top level of the object, with an
  # empty `metadata`. Mapping only the nested shape dropped name, email,
  # cellphone and taxId from every response.
  describe "the shape the API actually returns" do
    subject(:customer) do
      described_class.new(
        "id" => "cust_1", "name" => "Ana", "email" => "ana@example.com",
        "cellphone" => "11999998888", "taxId" => "111.444.777-35",
        "metadata" => {}, "devMode" => true
      )
    end

    it "exposes the name" do
      expect(customer.name).to eq("Ana")
    end

    it "exposes the email" do
      expect(customer.email).to eq("ana@example.com")
    end

    it "exposes the cellphone" do
      expect(customer.cellphone).to eq("11999998888")
    end

    it "exposes the tax id" do
      expect(customer.tax_id).to eq("111.444.777-35")
    end

    it "reports dev mode" do
      expect(customer.dev_mode?).to be true
    end

    # `customer.metadata.name` is what the README documented, so it has to keep
    # answering even though the API sends the fields flat.
    it "still answers through metadata" do
      expect(customer.metadata.name).to eq("Ana")
    end

    it "exposes the email through metadata too" do
      expect(customer.metadata.email).to eq("ana@example.com")
    end
  end

  describe "the nested shape older code builds" do
    subject(:customer) do
      described_class.new("id" => "cust_2", "metadata" => { "name" => "Nested", "email" => "n@e.com" })
    end

    it "keeps reading metadata" do
      expect(customer.metadata.name).to eq("Nested")
    end

    it "does not invent a top-level value" do
      expect(customer.name).to be_nil
    end
  end
end
