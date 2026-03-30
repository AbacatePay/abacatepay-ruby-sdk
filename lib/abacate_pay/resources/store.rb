# frozen_string_literal: true

module AbacatePay
  module Resources
    class Store < Resource
      RESOURCE_PROPERTIES = {
        balance: "AbacatePay::Resources::Store::Balance"
      }.freeze

      attr_reader :id, :name, :balance

      def initialize(data)
        fill(data)
      end

      private

      def process_value(property, value)
        return nil if value.nil?

        if RESOURCE_PROPERTIES.key?(property.to_sym)
          initialize_resource(Object.const_get(RESOURCE_PROPERTIES[property.to_sym]), value)
        else
          value
        end
      end

      protected

      attr_writer :id, :name, :balance
    end
  end
end

require "abacate_pay/resources/store/balance"
