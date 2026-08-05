# frozen_string_literal: true

module AbacatePay
  module Enums
    module Products
      class Cycles
        WEEKLY = "WEEKLY"
        MONTHLY = "MONTHLY"
        SEMIANNUALLY = "SEMIANNUALLY"
        ANNUALLY = "ANNUALLY"

        def self.values
          [WEEKLY, MONTHLY, SEMIANNUALLY, ANNUALLY]
        end

        def self.valid?(value)
          values.include?(value)
        end

        def self.validate!(value)
          raise ArgumentError, "Invalid product cycle: #{value}" unless valid?(value)

          value
        end
      end
    end
  end
end
