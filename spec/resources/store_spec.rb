# frozen_string_literal: true

RSpec.describe AbacatePay::Resources::Store do
  describe "#initialize" do
    context "with API data" do
      let(:store) do
        described_class.new({
                              "id" => "store-1",
                              "name" => "My Store",
                              "balance" => {
                                "available" => 10_000,
                                "pending" => 500,
                                "blocked" => 0
                              }
                            })
      end

      it("sets id") { expect(store.id).to eq("store-1") }
      it("sets name") { expect(store.name).to eq("My Store") }

      it "sets balance as Store::Balance" do
        expect(store.balance).to be_a(AbacatePay::Resources::Store::Balance)
      end

      it("maps balance.available") { expect(store.balance.available).to eq(10_000) }
      it("maps balance.pending") { expect(store.balance.pending).to eq(500) }
      it("maps balance.blocked") { expect(store.balance.blocked).to eq(0) }
    end

    context "with empty data" do
      it "sets all attributes to nil" do
        store = described_class.new({})
        expect(store.id).to be_nil
        expect(store.balance).to be_nil
      end
    end
  end
end
