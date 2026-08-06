# frozen_string_literal: true

# Loading the gem the way Bundler does must work without a `require:` option.
RSpec.describe "Gem entry points" do
  # Runs in a clean process: the suite has already required the SDK, so an
  # in-process require would pass no matter what.
  def load_in_clean_process(statement)
    lib = File.expand_path("../lib", __dir__)
    system(RbConfig.ruby, "-I#{lib}", "-e", statement, out: File::NULL, err: File::NULL)
  end

  let(:configure) { 'AbacatePay.configure { |c| c.api_token = "t" }' }

  it "loads via the gem name, which is what Bundler requires" do
    expect(load_in_clean_process(%(require "abacatepay-ruby"; #{configure}))).to be true
  end

  it "loads via the underscored path" do
    expect(load_in_clean_process(%(require "abacate_pay"; #{configure}))).to be true
  end

  it "exposes the full API through the gem-name entry point" do
    statement = 'require "abacatepay-ruby"; exit(AbacatePay.respond_to?(:checkouts) ? 0 : 1)'

    expect(load_in_clean_process(statement)).to be true
  end
end
