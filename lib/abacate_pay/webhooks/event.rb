# frozen_string_literal: true

module AbacatePay
  module Webhooks
    # A parsed webhook event.
    #
    # Accepts both the camelCase and snake_case spellings AbacatePay has used
    # for the envelope fields, so older and newer webhook versions both parse.
    class Event
      attr_reader :type, :data, :created_at

      # @param data [Hash] Parsed webhook payload
      def initialize(data)
        @type = data["event"] || data["type"]
        @data = data["data"]
        @created_at = data["createdAt"] || data["created_at"]
      end
    end
  end
end
