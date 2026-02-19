# frozen_string_literal: true

module AbacatePay
  module Enums
    module Billings
      # Enumeration defining billing frequencies.
      #
      # This enumeration is used to categorize different payment or billing frequencies.
      class Frequencies
        # One-time billing.
        # @return [String] Represents a billing that occurs only once
        ONE_TIME = "ONE_TIME"

        # Gets all valid frequency values
        # @return [Array<String>] List of all valid frequencies
        def self.values
          [ONE_TIME]
        end

        # Validates if a given value is a valid frequency
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
          raise ArgumentError, "Invalid frequency: #{value}" unless valid?(value)
          value
        end
      end
    end
  end
end