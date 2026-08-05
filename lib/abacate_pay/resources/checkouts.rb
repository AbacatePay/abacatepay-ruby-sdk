# frozen_string_literal: true

module AbacatePay
  module Resources
    # Represents a checkout session in the AbacatePay system.
    class Checkouts < Resource
      RESOURCE_PROPERTIES = {
        metadata: "AbacatePay::Resources::Billings::Metadata",
        customer: "AbacatePay::Resources::Customers",
        products: "AbacatePay::Resources::Billings::Product"
      }.freeze

      ENUM_PROPERTIES = {
        status: "AbacatePay::Enums::Checkouts::Statuses",
        frequency: "AbacatePay::Enums::Billings::Frequencies",
        methods: "AbacatePay::Enums::Billings::Methods"
      }.freeze

      DATETIME_PROPERTIES = %w[created_at updated_at].freeze

      attr_reader :id, :url, :amount, :status, :dev_mode, :methods,
                  :products, :metadata, :customer, :coupons, :external_id,
                  :frequency, :created_at, :updated_at,
                  # BOLETO-only: due date (YYYY-MM-DD) plus late-payment charges.
                  :due_date, :interest, :fine,
                  # CARD-only: maximum number of instalments offered.
                  :max_installments,
                  # Order bump shown at checkout, and free-form merchant data.
                  :up_sell_product_id, :custom_metadata

      def initialize(data)
        fill(data)
      end

      def dev_mode?
        @dev_mode
      end

      private

      def process_value(property, value)
        return nil if value.nil?

        if DATETIME_PROPERTIES.include?(property)
          initialize_date_time(value)
        elsif ENUM_PROPERTIES.key?(property.to_sym)
          process_enum_value(property, value)
        elsif RESOURCE_PROPERTIES.key?(property.to_sym)
          process_resource_value(property, value)
        else
          value
        end
      end

      def process_enum_value(property, value)
        enum_class = Object.const_get(ENUM_PROPERTIES[property.to_sym])

        if value.is_a?(Array)
          value.map { |item| initialize_enum(enum_class, item) }
        else
          initialize_enum(enum_class, value)
        end
      end

      def process_resource_value(property, value)
        resource_class = Object.const_get(RESOURCE_PROPERTIES[property.to_sym])

        if property.to_s == "products" && value.is_a?(Array)
          value.map { |item| initialize_resource(resource_class, item) }
        else
          initialize_resource(resource_class, value)
        end
      end

      protected

      attr_writer :id, :url, :amount, :status, :dev_mode, :methods,
                  :products, :metadata, :customer, :coupons, :external_id,
                  :frequency, :created_at, :updated_at,
                  :due_date, :interest, :fine, :max_installments,
                  :up_sell_product_id, :custom_metadata
    end
  end
end
