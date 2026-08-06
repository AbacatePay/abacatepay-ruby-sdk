# frozen_string_literal: true

module AbacatePay
  module Enums
    module Checkouts
      class Statuses
        PENDING = "PENDING"
        EXPIRED = "EXPIRED"
        CANCELLED = "CANCELLED"
        PAID = "PAID"
        REFUNDED = "REFUNDED"

        # Reusable payment links are created ACTIVE rather than PENDING.
        ACTIVE = "ACTIVE"

        def self.values
          [PENDING, EXPIRED, CANCELLED, PAID, REFUNDED, ACTIVE]
        end

        def self.valid?(value)
          values.include?(value)
        end

        def self.validate!(value)
          raise ArgumentError, "Invalid checkout status: #{value}" unless valid?(value)

          value
        end
      end
    end
  end
end
