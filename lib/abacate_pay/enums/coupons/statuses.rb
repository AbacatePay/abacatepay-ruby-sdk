# frozen_string_literal: true

module AbacatePay
  module Enums
    module Coupons
      class Statuses
        ACTIVE = "ACTIVE"
        INACTIVE = "INACTIVE"
        EXPIRED = "EXPIRED"

        # What the API returns for a coupon turned off through `toggle`.
        DISABLED = "DISABLED"

        def self.values
          [ACTIVE, INACTIVE, EXPIRED, DISABLED]
        end

        def self.valid?(value)
          values.include?(value)
        end

        def self.validate!(value)
          raise ArgumentError, "Invalid coupon status: #{value}" unless valid?(value)

          value
        end
      end
    end
  end
end
