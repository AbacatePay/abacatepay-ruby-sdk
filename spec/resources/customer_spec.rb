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
end
