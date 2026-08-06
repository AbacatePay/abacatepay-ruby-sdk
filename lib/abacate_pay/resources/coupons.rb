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

      attr_reader :id, :discount, :discount_kind, :max_redeems,
                  :status, :notes, :dev_mode, :created_at, :updated_at

      # @return [Integer, nil] Times the coupon has been redeemed
      attr_reader :redeems_count

      def initialize(data)
        fill(data)
      end

      # The coupon code.
      #
      # The API uses the code as the object's `id` and sends no separate
      # `code` field, so this reader was always nil for API data.
      #
      # @return [String, nil]
      def code
        @code || @id
      end

      # @return [Integer, nil] Times the coupon has been redeemed
      #
      # @deprecated The API calls this `redeemsCount`; use {#redeems_count}.
      def current_redeems
        @current_redeems || @redeems_count
      end

      # @return [Boolean, nil] Whether the coupon belongs to Dev mode
      def dev_mode?
        @dev_mode
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
                  :current_redeems, :redeems_count, :status, :notes,
                  :dev_mode, :created_at, :updated_at
    end
  end
end
