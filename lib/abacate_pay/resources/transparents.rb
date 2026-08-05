# frozen_string_literal: true

module AbacatePay
  module Resources
    # Represents a transparent checkout (PIX or boleto) in the AbacatePay system.
    class Transparents < Resource
      RESOURCE_PROPERTIES = {
        customer: "AbacatePay::Resources::Customers"
      }.freeze

      DATETIME_PROPERTIES = %w[created_at updated_at expires_at].freeze

      # qr_code and qr_code_image are defined below rather than generated here:
      # they fall back to the br_code fields the API actually sends.
      attr_reader :id, :amount, :status, :method, :description,
                  :expires_in, :customer,
                  :metadata, :dev_mode, :created_at, :updated_at,
                  # Boleto: due date sent on create, plus the payment slip the
                  # API returns: digitable line, viewing URL, and the PIX
                  # fallback issued for the same charge.
                  :due_date, :bar_code, :url, :br_code, :br_code_base64,
                  :expires_at, :platform_fee, :receipt_url

      def initialize(data)
        fill(data)
      end

      # The API returns the copy-and-paste payload as `brCode` and the image as
      # `brCodeBase64`. Older documentation used `qrCode`/`qrCodeImage`, so both
      # spellings are accepted: the reader prefers the `qr*` value when the API
      # sends one and falls back to `br*`.
      #
      # @return [String, nil] PIX copy-and-paste payload
      def qr_code
        @qr_code || br_code
      end

      # @return [String, nil] PIX QR code image as a data URI
      def qr_code_image
        @qr_code_image || br_code_base64
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
                  :metadata, :dev_mode, :created_at, :updated_at,
                  :due_date, :bar_code, :url, :br_code, :br_code_base64,
                  :expires_at, :platform_fee, :receipt_url
    end
  end
end
