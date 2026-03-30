# frozen_string_literal: true

module AbacatePay
  module Enums
    module Coupons
      class DiscountKinds
        PERCENTAGE = "PERCENTAGE"
        FIXED = "FIXED"

        def self.values
          [PERCENTAGE, FIXED]
        end

        def self.valid?(value)
          values.include?(value)
        end

        def self.validate!(value)
          raise ArgumentError, "Invalid discount kind: #{value}" unless valid?(value)
          value
        end
      end
    end
  end
end
