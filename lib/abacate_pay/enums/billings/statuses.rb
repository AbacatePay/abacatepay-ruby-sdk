# frozen_string_literal: true

module AbacatePay
  module Enums
    module Billings
      # Enumeration defining billing statuses.
      #
      # This enumeration is used to represent the various statuses that a billing process can have.
      class Statuses
        # Indicates that the billing is pending and has not yet been processed.
        # @return [String]
        PENDING = "PENDING"

        # Indicates that the billing has expired and is no longer valid.
        # @return [String]
        EXPIRED = "EXPIRED"

        # Indicates that the billing has been cancelled and will not be processed.
        # @return [String]
        CANCELLED = "CANCELLED"

        # Indicates that the billing has been successfully paid.
        # @return [String]
        PAID = "PAID"

        # Indicates that the billing has been refunded to the payer.
        # @return [String]
        REFUNDED = "REFUNDED"

        # Gets all valid status values
        # @return [Array<String>] List of all valid statuses
        def self.values
          [PENDING, EXPIRED, CANCELLED, PAID, REFUNDED]
        end

        # Validates if a given value is a valid status
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
          raise ArgumentError, "Invalid status: #{value}" unless valid?(value)
          value
        end
      end
    end
  end
end