# frozen_string_literal: true

module AbacatePay
  # Configuration class for the AbacatePay SDK
  #
  # This class handles all configuration options for the SDK, including
  # API credentials and request behaviour.
  #
  # @api public
  class Configuration
    # The only base URL AbacatePay serves. The v1 prefix was retired and now
    # answers `{"error":"Not found"}` for every path, so there is nothing to
    # negotiate between.
    API_BASE_URL = "https://api.abacatepay.com/v2"

    # @return [String] API token for authentication
    attr_accessor :api_token

    # @return [Integer] Request timeout in seconds
    attr_accessor :timeout

    # Initialize a new configuration with default values
    #
    # @api public
    def initialize
      @timeout = 30
      @api_token = nil
    end

    # @deprecated The environment is determined by the API key itself — keys
    #   created in Dev mode produce simulated transactions, production keys
    #   produce real ones. This setting has never had any effect and is kept
    #   only so existing initializers keep loading.
    # @return [nil]
    attr_reader :environment

    # @deprecated See {#environment}.
    # @param value [Symbol] Ignored
    # @return [void]
    def environment=(value)
      @environment = value
      warn "[DEPRECATION] AbacatePay config.environment has no effect and will be removed. " \
           "The environment is determined by the API key: Dev mode keys simulate transactions, " \
           "production keys do not."
    end

    # Validates the configuration
    #
    # @raise [ConfigurationError] if any required settings are missing or invalid
    # @return [void]
    #
    # @api public
    def validate!
      raise ConfigurationError, "API token is required" if api_token.nil?
      raise ConfigurationError, "API token must not be empty" if api_token.to_s.strip.empty?
    end

    # Gets the base API URL
    #
    # @return [String] The base API URL
    #
    # @api public
    def api_url
      API_BASE_URL
    end
  end
end
