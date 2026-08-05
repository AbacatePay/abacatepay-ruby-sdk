# frozen_string_literal: true

module AbacatePay
  module Enums
    module Payouts
      class Statuses
        PENDING = "PENDING"
        COMPLETE = "COMPLETE"
        CANCELLED = "CANCELLED"
        EXPIRED = "EXPIRED"
        REFUNDED = "REFUNDED"

        def self.values
          [PENDING, COMPLETE, CANCELLED, EXPIRED, REFUNDED]
        end

        def self.valid?(value)
          values.include?(value)
        end

        def self.validate!(value)
          raise ArgumentError, "Invalid payout status: #{value}" unless valid?(value)

          value
        end
      end
    end
  end
end
