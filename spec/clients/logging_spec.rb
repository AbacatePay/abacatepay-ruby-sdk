# frozen_string_literal: true

require "logger"
require "stringio"

# Debugging an integration used to mean wrapping Faraday from the outside. The
# logger is opt-in, and must never write the bearer token.
RSpec.describe "Request logging" do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }

  before do
    AbacatePay.configure do |config|
      config.api_token = "abc_live_supersecrettoken"
      config.logger = logger
    end

    allow(Faraday).to receive(:new).and_wrap_original do |original, **options, &block|
      original.call(**options) do |builder|
        block&.call(builder)
        builder.adapter :test, stubs
      end
    end

    stubs.get("/v2/customers/list") do
      [200, { "Content-Type" => "application/json" }, { "data" => [] }.to_json]
    end
    AbacatePay.customers.list
  end

  it "logs the request" do
    expect(log_output.string).to include("/v2/customers/list")
  end

  it "never writes the bearer token" do
    expect(log_output.string).not_to include("abc_live_supersecrettoken")
  end

  it "redacts the Authorization header" do
    expect(log_output.string).to match(/\[REDACTED\]/i)
  end

  context "when no logger is configured" do
    before { AbacatePay.configure { |config| config.logger = nil } }

    it "stays silent" do
      before_size = log_output.string.size
      stubs.get("/v2/customers/list") do
        [200, { "Content-Type" => "application/json" }, { "data" => [] }.to_json]
      end
      AbacatePay.customers.list

      expect(log_output.string.size).to eq(before_size)
    end
  end
end
