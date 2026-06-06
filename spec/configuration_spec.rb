# frozen_string_literal: true

RSpec.describe AbacatePay::Configuration do
  subject(:config) { described_class.new }

  describe "#api_url" do
    context "with a v2 token prefix" do
      %w[abc_dev_ abc_live_ abc_prod_].each do |prefix|
        it "routes #{prefix}* tokens to v2" do
          config.api_token = "#{prefix}secret123"
          expect(config.api_url).to eq("https://api.abacatepay.com/v2")
        end
      end
    end

    context "with a non-v2 token" do
      it "falls back to v1 for legacy tokens" do
        config.api_token = "legacy_token_123"
        expect(config.api_url).to eq("https://api.abacatepay.com/v1")
      end

      it "falls back to v1 when the token is nil" do
        config.api_token = nil
        expect(config.api_url).to eq("https://api.abacatepay.com/v1")
      end
    end
  end
end
