# frozen_string_literal: true

require "uri"

module AbacatePay
  module Clients
    # Client for managing webhook endpoint registrations in the AbacatePay API.
    #
    # This manages *where* AbacatePay delivers events. To verify and parse an
    # inbound delivery, use {AbacatePay::Webhooks.construct_event}.
    class WebhookClient < Client
      URI = "webhooks"

      # Shortest signing secret the API accepts.
      MINIMUM_SECRET_LENGTH = 32

      # @param client [Faraday::Connection, nil] Optional Faraday client
      def initialize(client = nil)
        super(URI, client)
      end

      # @param params [Hash] Optional params (limit, after, before, startDate, endDate)
      # @return [Array<Resources::WebhookEndpoints>]
      def list(**params)
        response = request("GET", "list", params: params.empty? ? nil : params)
        build_list(response, Resources::WebhookEndpoints)
      end

      # @param id [String] The webhook ID
      # @return [Resources::WebhookEndpoints]
      def get(id)
        response = request("GET", "get", params: { id: id })
        Resources::WebhookEndpoints.new(response)
      end

      # Registers a new webhook endpoint.
      #
      # The secret is what AbacatePay signs deliveries with, pass the same
      # value to {AbacatePay::Webhooks.construct_event} when handling them.
      #
      # @param name [String] Identifying name
      # @param endpoint [String] HTTPS URL that will receive the events
      # @param secret [String] Signing secret
      # @param events [Array<String>] Event types to subscribe to
      # @return [Resources::WebhookEndpoints] The created webhook
      # @raise [ArgumentError] if the endpoint is not HTTPS, the event list is
      #   empty, or the secret is shorter than the API accepts
      def create(name:, endpoint:, secret:, events:)
        raise ArgumentError, "endpoint must be an HTTPS URL, got #{endpoint.inspect}" unless https_url?(endpoint)
        raise ArgumentError, "events must not be empty" if Array(events).empty?

        # The API rejects anything shorter with
        # "Expected string length greater or equal to 32".
        if secret.to_s.length < MINIMUM_SECRET_LENGTH
          raise ArgumentError,
                "secret must be at least #{MINIMUM_SECRET_LENGTH} characters, got #{secret.to_s.length}"
        end

        response = request("POST", "create", json: {
                             name: name,
                             endpoint: endpoint,
                             secret: secret,
                             events: Array(events)
                           })
        Resources::WebhookEndpoints.new(response)
      end

      # @param id [String] The webhook ID
      # @return [Resources::WebhookEndpoints, nil] The deleted webhook, or nil
      #   when the API confirms the deletion without echoing the object
      def delete(id)
        # The API reads the id from the query string here, like
        # transparents/simulate-payment. Sending it in the body fails with
        # "Expected property 'id' to be string but found: undefined".
        response = request("POST", "delete", params: { id: id }, json: {})
        return nil if response.nil?

        Resources::WebhookEndpoints.new(response)
      end

      private

      # AbacatePay only delivers to HTTPS endpoints; failing here beats a
      # confusing rejection after the round trip.
      #
      # The class-level URI constant shadows Ruby's URI module inside this
      # class, so the global scope operator is required.
      #
      # @param value [String] The candidate URL
      # @return [Boolean]
      def https_url?(value)
        uri = ::URI::DEFAULT_PARSER.parse(value.to_s)
        uri.is_a?(::URI::HTTPS) && !uri.host.nil?
      rescue ::URI::InvalidURIError
        false
      end
    end
  end
end
