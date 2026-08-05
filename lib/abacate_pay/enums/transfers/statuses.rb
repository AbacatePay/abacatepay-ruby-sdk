# frozen_string_literal: true

module AbacatePay
  module Enums
    module Transfers
      class Statuses
        PENDING = "PENDING"
        COMPLETE = "COMPLETE"
        CANCELLED = "CANCELLED"
        EXPIRED = "EXPIRED"
        REFUNDED = "REFUNDED"
        FAILED = "FAILED"

        def self.values
          [PENDING, COMPLETE, CANCELLED, EXPIRED, REFUNDED, FAILED]
        end

        def self.valid?(value)
          values.include?(value)
        end

        def self.validate!(value)
          raise ArgumentError, "Invalid transfer status: #{value}" unless valid?(value)

          value
        end
      end
    end
  end
end
