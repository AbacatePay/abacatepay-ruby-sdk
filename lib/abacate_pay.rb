# frozen_string_literal: true

require "abacate_pay/version"
require "abacate_pay/configuration"

# Main module for AbacatePay SDK integration
module AbacatePay
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ApiError < Error; end

  class << self
    # Gets or sets the global configuration
    attr_accessor :configuration
  end

  # Configures the SDK
  #
  # @example
  #   AbacatePay.configure do |config|
  #     config.api_token = "your-token-here"
  #     config.environment = :sandbox
  #   end
  #
  # @yield [config] Configuration object
  # @return [void]
  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
    configuration.validate!
  end

  # Resets the configuration to defaults
  #
  # @return [void]
  def self.reset!
    self.configuration = Configuration.new
    @customers = nil
    @products = nil
    @coupons = nil
    @checkouts = nil
    @subscriptions = nil
    @transparents = nil
    @pix = nil
    @payouts = nil
    @store = nil
  end

  # @return [Clients::CustomerClient] Customer API client
  def self.customers
    @customers ||= Clients::CustomerClient.new
  end

  # @return [Clients::ProductClient] Product API client
  def self.products
    @products ||= Clients::ProductClient.new
  end

  # @return [Clients::CouponClient] Coupon API client
  def self.coupons
    @coupons ||= Clients::CouponClient.new
  end

  # @return [Clients::CheckoutClient] Checkout API client
  def self.checkouts
    @checkouts ||= Clients::CheckoutClient.new
  end

  # @return [Clients::SubscriptionClient] Subscription API client
  def self.subscriptions
    @subscriptions ||= Clients::SubscriptionClient.new
  end

  # @return [Clients::TransparentClient] PIX Transparent API client
  def self.transparents
    @transparents ||= Clients::TransparentClient.new
  end

  # @return [Clients::PixClient] PIX Transfer API client
  def self.pix
    @pix ||= Clients::PixClient.new
  end

  # @return [Clients::PayoutClient] Payout API client
  def self.payouts
    @payouts ||= Clients::PayoutClient.new
  end

  # @return [Clients::StoreClient] Store API client
  def self.store
    @store ||= Clients::StoreClient.new
  end
end

# Autoload all components
Dir[File.join(__dir__, "abacate_pay", "**", "*.rb")].sort.each { |file| require file }