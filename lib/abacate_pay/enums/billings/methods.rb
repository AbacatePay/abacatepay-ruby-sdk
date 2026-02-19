# frozen_string_literal: true

module AbacatePay
  module Enums
    module Billings
      # Enumeration defining billing methods.
      #
      # This enumeration is used to represent different payment methods available for billing.
      class Methods
        # PIX payment method.
        # @return [String] Represents the PIX payment method, a popular instant payment system in Brazil
        PIX = "PIX"

        # Gets all valid method values
        # @return [Array<String>] List of all valid payment methods
        def self.values
          [PIX]
        end

        # Validates if a given value is a valid method
        # @param value [String] The value to validate
        # @return [Boolean] true if valid, false otherwise
        def self.valid?(value)
          values.include?(value)
        end

        # Validates and returns the value if valid
        # @param value [String] The value to validate
        # @return [String] The validated value
        # @raise [ArgumentError] if value is invalid
        def self.validate!(value)
          raise ArgumentError, "Invalid payment method: #{value}" unless valid?(value)
          value
        end
      end
    end
  end
end