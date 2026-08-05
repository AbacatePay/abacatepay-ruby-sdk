# frozen_string_literal: true

module AbacatePay
  module Resources
    # Represents a discount coupon in the AbacatePay system.
    class Coupons < Resource
      ENUM_PROPERTIES = {
        status: "AbacatePay::Enums::Coupons::Statuses",
        discount_kind: "AbacatePay::Enums::Coupons::DiscountKinds"
      }.freeze

      DATETIME_PROPERTIES = %w[created_at updated_at].freeze

      attr_reader :id, :code, :discount, :discount_kind, :max_redeems,
                  :current_redeems, :status, :created_at, :updated_at

      def initialize(data)
        fill(data)
      end

      private

      def process_value(property, value)
        return nil if value.nil?

        if DATETIME_PROPERTIES.include?(property)
          initialize_date_time(value)
        elsif ENUM_PROPERTIES.key?(property.to_sym)
          initialize_enum(Object.const_get(ENUM_PROPERTIES[property.to_sym]), value)
        else
          value
        end
      end

      protected

      attr_writer :id, :code, :discount, :discount_kind, :max_redeems,
                  :current_redeems, :status, :created_at, :updated_at
    end
  end
end
