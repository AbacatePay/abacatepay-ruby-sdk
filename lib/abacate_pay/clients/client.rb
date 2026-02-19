# frozen_string_literal: true

require "faraday"

module AbacatePay
  module Clients
    # Client class for interacting with the AbacatePay API.
    #
    # This class handles API requests using Faraday and provides a way to manage
    # authentication and communication with the AbacatePay service.
    class Client
      # @param uri [String] The specific API endpoint to interact with
      # @param client [Faraday::Connection, nil] Optional Faraday client for custom configurations
      def initialize(uri, client = nil)
        @client = client || build_client(uri)
      end

      private

      # Sends an HTTP request to the API
      #
      # @param method [String] The HTTP method (e.g., GET, POST)
      # @param uri [String] The endpoint URI relative to the base URI
      # @param options [Hash] Optional settings and parameters for the request
      # @return [Hash] The response data
      # @raise [ApiError] If an error occurs during the request
      def request(method, uri, options = {})
        response = @client.public_send(method.downcase) do |req|
          req.url uri
          req.body = options[:json].to_json if options[:json]
        end

        JSON.parse(response.body).fetch("data")
      rescue Faraday::Error => e
        handle_request_error(e)
      rescue StandardError => e
        raise ApiError, "Unexpected error: #{e.message}"
      end

      # Builds a new Faraday client with default configuration
      #
      # @param uri [String] The endpoint URI
      # @return [Faraday::Connection] Configured Faraday client
      def build_client(uri)
        Faraday.new(
          url: "#{AbacatePay.configuration.api_url}/#{uri}/",
          headers: {
            "Content-Type" => "application/json",
            "Authorization" => "Bearer #{AbacatePay.configuration.api_token}"
          }
        )
      end

      # Handles API request errors
      #
      # @param error [Faraday::Error] The error to handle
      # @raise [ApiError] With appropriate error message
      def handle_request_error(error)
        error_message = if error.response&.body
          response_body = JSON.parse(error.response.body)
          response_body["message"] || response_body["error"]
        end

        raise ApiError, "Request error: #{error_message || error.message}"
      end
    end
  end
end