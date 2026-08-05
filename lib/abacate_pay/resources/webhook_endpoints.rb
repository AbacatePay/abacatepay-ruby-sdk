# frozen_string_literal: true

module AbacatePay
  module Resources
    # Represents a registered webhook endpoint in the AbacatePay system.
    #
    # This is the endpoint *registration* — the URL AbacatePay delivers events
    # to. For verifying and parsing an inbound delivery, see {AbacatePay::Webhooks}.
    class WebhookEndpoints < Resource
      # @return [String, nil] Webhook ID
      attr_accessor :id

      # @return [String, nil] Identifying name
      attr_accessor :name

      # @return [String, nil] HTTPS URL that receives the events
      attr_accessor :endpoint

      # @return [Array<String>, nil] Event types this endpoint subscribes to
      attr_accessor :events

      # @return [Boolean, nil] Whether the endpoint is active
      attr_accessor :active

      # @return [DateTime, nil] Creation timestamp
      attr_accessor :created_at

      # @return [DateTime, nil] Last update timestamp
      attr_accessor :updated_at

      # @param data [Hash] The webhook properties
      def initialize(data)
        fill(data)
      end

      private

      # @param property [String] The property name
      # @param value [Object] The raw value
      # @return [Object] The processed value
      def process_value(property, value)
        case property
        when "created_at", "updated_at" then initialize_date_time(value)
        else value
        end
      end
    end
  end
end
