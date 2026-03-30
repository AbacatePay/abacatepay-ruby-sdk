# frozen_string_literal: true

module AbacatePay
  module Resources
    class Transparents < Resource
      RESOURCE_PROPERTIES = {
        customer: "AbacatePay::Resources::Customers"
      }.freeze

      DATETIME_PROPERTIES = %w[created_at updated_at].freeze

      attr_reader :id, :amount, :status, :method, :description,
                  :expires_in, :qr_code, :qr_code_image, :customer,
                  :metadata, :dev_mode, :created_at, :updated_at

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
        elsif RESOURCE_PROPERTIES.key?(property.to_sym)
          initialize_resource(Object.const_get(RESOURCE_PROPERTIES[property.to_sym]), value)
        else
          value
        end
      end

      protected

      attr_writer :id, :amount, :status, :method, :description,
                  :expires_in, :qr_code, :qr_code_image, :customer,
                  :metadata, :dev_mode, :created_at, :updated_at
    end
  end
end
