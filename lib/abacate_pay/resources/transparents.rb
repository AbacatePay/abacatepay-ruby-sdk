# frozen_string_literal: true

module AbacatePay
  module Resources
    class Transparents < Resource
      RESOURCE_PROPERTIES = {
        customer: "AbacatePay::Resources::Customers"
      }.freeze

      DATETIME_PROPERTIES = %w[created_at updated_at expires_at].freeze

      attr_reader :id, :amount, :status, :method, :description,
                  :expires_in, :expires_at, :customer, :metadata,
                  :br_code, :br_code_base64, :platform_fee, :receipt_url,
                  :dev_mode, :created_at, :updated_at

      def initialize(data)
        fill(data)
      end

      def dev_mode?
        @dev_mode
      end

      # A API responde o copia-e-cola como `brCode` e a imagem como
      # `brCodeBase64` (data URI). Versões anteriores da documentação usavam
      # `qrCode`/`qrCodeImage`, então aceitamos os dois nomes: os readers
      # preferem o valor `qr*` quando presente e caem para `br*`.
      def qr_code
        @qr_code || br_code
      end

      def qr_code_image
        @qr_code_image || br_code_base64
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
                  :expires_in, :expires_at, :qr_code, :qr_code_image,
                  :br_code, :br_code_base64, :platform_fee, :receipt_url,
                  :customer, :metadata, :dev_mode, :created_at, :updated_at
    end
  end
end
