# frozen_string_literal: true

RSpec.describe AbacatePay::Enums::Webhooks::EventTypes do
  describe ".values" do
    it "returns 15 event types" do
      expect(described_class.values.size).to eq(15)
    end

    it "includes checkout events" do
      expect(described_class.values).to include("checkout.completed", "checkout.refunded", "checkout.disputed")
    end

    it "includes transfer events" do
      expect(described_class.values).to include("transfer.completed", "transfer.failed")
    end
  end

  # Dunning and trial signals were missing until 1.1.0.
  describe "subscription lifecycle events" do
    it "includes payment_failed" do
      expect(described_class.values).to include("subscription.payment_failed")
    end

    it "includes trial_started" do
      expect(described_class.values).to include("subscription.trial_started")
    end
  end

  describe ".valid?" do
    it("returns true for checkout.completed") { expect(described_class.valid?("checkout.completed")).to be true }
    it("returns false for unknown.event") { expect(described_class.valid?("unknown.event")).to be false }
  end

  describe ".validate!" do
    it "returns the value when valid" do
      expect(described_class.validate!("payout.completed")).to eq("payout.completed")
    end

    it "raises ArgumentError for an invalid event type" do
      expect { described_class.validate!("invalid") }.to raise_error(ArgumentError)
    end
  end
end
