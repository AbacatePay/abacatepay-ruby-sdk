# frozen_string_literal: true

require "abacate_pay/version"
require "abacate_pay/configuration"

# Main module for AbacatePay SDK integration
module AbacatePay
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ApiError < Error; end

  class << self
    # @return [Configuration, nil] The global configuration
    attr_reader :configuration

    # Replacing the configuration invalidates every memoized client, so a
    # client built against the previous credentials can never outlive them.
    #
    # @param value [Configuration, nil] The new configuration
    # @return [void]
    def configuration=(value)
      @configuration = value
      reset_clients!
    end
  end

  # Configures the SDK
  #
  # Memoized clients are discarded so a token changed at runtime takes effect
  # immediately. Without this, a client built before the change keeps sending
  # the old bearer token.
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
    reset_clients!
  end

  # Resets the configuration to defaults
  #
  # @return [void]
  def self.reset!
    self.configuration = Configuration.new
    reset_clients!
  end

  # Returns the configuration, refusing to proceed if the SDK was never set up.
  #
  # Forgetting to call {configure} is the most common first-run mistake; without
  # this the failure surfaces as `NoMethodError: undefined method 'api_url' for
  # nil` from deep inside the client.
  #
  # @return [Configuration] The active configuration
  # @raise [ConfigurationError] if {configure} has not been called
  def self.configuration!
    configuration || raise(
      ConfigurationError,
      "AbacatePay is not configured. Call AbacatePay.configure { |c| c.api_token = ENV['ABACATEPAY_API_KEY'] } first."
    )
  end

  # Discards every memoized client so the next call rebuilds from current config
  #
  # @return [void]
  def self.reset_clients!
    @clients = {}
  end

  # @return [Hash{Symbol => Clients::Client}] Memoized clients, keyed by name
  def self.clients
    @clients ||= {}
  end
  private_class_method :clients

  # @return [Clients::CustomerClient] Customer API client
  def self.customers
    clients[:customers] ||= Clients::CustomerClient.new
  end

  # @return [Clients::ProductClient] Product API client
  def self.products
    clients[:products] ||= Clients::ProductClient.new
  end

  # @return [Clients::CouponClient] Coupon API client
  def self.coupons
    clients[:coupons] ||= Clients::CouponClient.new
  end

  # @return [Clients::CheckoutClient] Checkout API client
  def self.checkouts
    clients[:checkouts] ||= Clients::CheckoutClient.new
  end

  # @return [Clients::SubscriptionClient] Subscription API client
  def self.subscriptions
    clients[:subscriptions] ||= Clients::SubscriptionClient.new
  end

  # @return [Clients::TransparentClient] PIX Transparent API client
  def self.transparents
    clients[:transparents] ||= Clients::TransparentClient.new
  end

  # @return [Clients::PixClient] PIX Transfer API client
  def self.pix
    clients[:pix] ||= Clients::PixClient.new
  end

  # @return [Clients::PayoutClient] Payout API client
  def self.payouts
    clients[:payouts] ||= Clients::PayoutClient.new
  end

  # @return [Clients::StoreClient] Store API client
  def self.store
    clients[:store] ||= Clients::StoreClient.new
  end

  # @return [Clients::PaymentLinkClient] Reusable payment link API client
  def self.payment_links
    clients[:payment_links] ||= Clients::PaymentLinkClient.new
  end

  # Webhook *endpoint registration*. To verify an inbound delivery, use
  # {AbacatePay::Webhooks.construct_event}.
  #
  # @return [Clients::WebhookClient] Webhook management API client
  def self.webhook_endpoints
    clients[:webhook_endpoints] ||= Clients::WebhookClient.new
  end
end

# Components are required explicitly, in dependency order. A glob would load
# clients/billing_client.rb before clients/client.rb and blow up on the
# superclass, and it silently swallows files that were never wired up.
require "abacate_pay/enums"
require "abacate_pay/resources"
require "abacate_pay/clients"
require "abacate_pay/webhooks"
