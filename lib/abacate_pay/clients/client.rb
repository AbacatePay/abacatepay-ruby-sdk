# frozen_string_literal: true

require "faraday"
require "faraday/retry"

module AbacatePay
  module Clients
    # Client class for interacting with the AbacatePay API.
    #
    # This class handles API requests using Faraday and provides a way to manage
    # authentication and communication with the AbacatePay service.
    class Client
      # Statuses worth retrying. 429 is rate limiting and 5xx are transient -
      # AbacatePay's own reference tells integrators to back off on both.
      RETRIABLE_STATUSES = [429, 500, 502, 503, 504].freeze

      # Only methods that are safe to repeat. POST is excluded: retrying
      # `checkouts/create` after a timeout could charge a customer twice, and
      # the API exposes no idempotency key to make that safe.
      RETRIABLE_METHODS = %i[get head options].freeze

      # Passing `exceptions` replaces faraday-retry's defaults rather than
      # adding to them, and Faraday::RetriableResponse is what the middleware
      # raises internally for a retriable status. Omitting it silently disables
      # status-code retries altogether.
      RETRIABLE_EXCEPTIONS = [
        Faraday::RetriableResponse,
        Faraday::TimeoutError,
        Faraday::ConnectionFailed,
        Errno::ETIMEDOUT
      ].freeze

      # @param uri [String] The specific API endpoint to interact with
      # @param client [Faraday::Connection, nil] Optional Faraday client for custom configurations
      def initialize(uri, client = nil)
        @client = client || build_client(uri)
      end

      # Yields every page of a list endpoint, following the cursor.
      #
      # @param params [Hash] Params forwarded to each `list` call
      # @yield [AbacatePay::Collection] Each page in order
      # @return [void]
      def each_page(**params)
        return to_enum(:each_page, **params) unless block_given?

        cursor = params.delete(:after)
        loop do
          page = list(**params, **(cursor ? { after: cursor } : {}))
          yield page
          break unless page.respond_to?(:has_more?) && page.has_more? && page.next_cursor

          cursor = page.next_cursor
        end
      end

      # Yields every record across every page.
      #
      # Prefer this over `list` when the result set can exceed the 100-item
      # page limit.
      #
      # @param params [Hash] Params forwarded to each `list` call
      # @yield [Object] Each resource
      # @return [void]
      def auto_paging_each(**params, &)
        return to_enum(:auto_paging_each, **params) unless block_given?

        each_page(**params) { |page| page.each(&) }
      end

      private

      # Sends an HTTP request to the API
      #
      # @param method [String] The HTTP method (e.g., GET, POST)
      # @param uri [String] The endpoint URI relative to the base URI
      # @param options [Hash] Optional settings and parameters for the request
      # @return [Hash, AbacatePay::Collection] The response data, a Collection
      #   when the API reports pagination, the raw data otherwise
      # @raise [ApiError] If an error occurs during the request
      def request(method, uri, options = {})
        response = send_request(method, uri, options)
        parsed = JSON.parse(response.body)
        raise ApiError, "API error: #{parsed["error"]}" if parsed["error"]

        extract_data(parsed)
      rescue Faraday::Error => e
        handle_request_error(e)
      rescue JSON::ParserError => e
        raise ApiError, "Malformed API response: #{e.message}"
      end

      # Pulls the payload out of the `{data, error, success}` envelope.
      #
      # Some endpoints answer a successful call with no `data` at all, for
      # example `webhooks/delete` returning `{"success":true,"error":null}`.
      # Treating that as malformed turned a working call into an ApiError.
      #
      # @param parsed [Hash] The decoded response body
      # @return [Object, nil] The payload, or nil when the call carries none
      # @raise [ApiError] if the envelope has neither data nor a success flag
      def extract_data(parsed)
        unless parsed.key?("data")
          return nil if parsed["success"]

          raise ApiError, "Unexpected API response: #{parsed.inspect[0, 120]}"
        end

        data = parsed["data"]
        # Preserve the cursor when the API sends one; dropping it made paging
        # past the first 100 records impossible.
        parsed["pagination"] ? Collection.new(data, parsed["pagination"]) : data
      end

      # Issues the HTTP call.
      #
      # @param method [String] The HTTP method
      # @param uri [String] The endpoint URI relative to the base URI
      # @param options [Hash] Params and JSON body
      # @return [Faraday::Response]
      def send_request(method, uri, options)
        @client.public_send(method.downcase) do |req|
          req.url uri
          req.params = options[:params] if options[:params]
          req.body = compact_payload(options[:json]).to_json if options[:json]
        end
      end

      # Removes nil values from an outgoing payload, at every depth.
      #
      # The API rejects explicit nulls: `{"cellphone": null}` comes back as
      # HTTP 400 "Expected property 'cellphone' to be string but found: null",
      # and payload builders naturally produce them for optional fields the
      # caller left unset. Doing this at the boundary means no endpoint, present
      # or future, can forget it.
      #
      # @param payload [Object] The payload about to be serialised
      # @return [Object] The payload without nil entries
      def compact_payload(payload)
        case payload
        when Hash
          payload.each_with_object({}) do |(key, value), result|
            next if value.nil?

            result[key] = compact_payload(value)
          end
        when Array
          payload.compact.map { |item| compact_payload(item) }
        else
          payload
        end
      end

      # Maps a list response into resources without losing the page cursor.
      #
      # @param response [Array, AbacatePay::Collection] The raw list response
      # @param resource_class [Class] The resource to instantiate per item
      # @return [Array, AbacatePay::Collection] Mapped items, still paginated
      #   when the API reported pagination
      def build_list(response, resource_class)
        items = Array(response).map { |data| resource_class.new(data) }
        response.is_a?(Collection) ? response.with_items(items) : items
      end

      # Builds a new Faraday client with default configuration
      #
      # @param uri [String] The endpoint URI
      # @return [Faraday::Connection] Configured Faraday client
      def build_client(uri)
        configuration = AbacatePay.configuration!
        base_url = uri.empty? ? "#{configuration.api_url}/" : "#{configuration.api_url}/#{uri}/"

        Faraday.new(
          url: base_url,
          headers: build_headers(configuration),
          # Without an explicit timeout a hung gateway blocks the caller's
          # thread indefinitely, inside a Rails request, that is an outage.
          request: {
            timeout: configuration.timeout,
            open_timeout: configuration.timeout
          }
        ) do |builder|
          configure_retries(builder, configuration)
          configure_logging(builder, configuration)
          builder.adapter Faraday.default_adapter
        end
      end

      # @param configuration [AbacatePay::Configuration] The active configuration
      # @return [Hash] Request headers
      def build_headers(configuration)
        {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{configuration.api_token}",
          "User-Agent" => "abacatepay-ruby/#{AbacatePay::VERSION} ruby/#{RUBY_VERSION}"
        }
      end

      # @param builder [Faraday::Connection] The connection being built
      # @param configuration [AbacatePay::Configuration] The active configuration
      # @return [void]
      def configure_retries(builder, configuration)
        return if configuration.max_retries.to_i <= 0

        # `retry_if` is deliberately left at its default (never retry outside
        # `methods`). Overriding it would re-enable retries for POST, which is
        # exactly what must not happen for charge creation.
        builder.request :retry,
                        max: configuration.max_retries,
                        interval: 0.5,
                        backoff_factor: 2,
                        max_interval: 8,
                        # Jitter: without it, every client that hit the same
                        # rate limit retries in lockstep and hits it again.
                        interval_randomness: 0.5,
                        retry_statuses: RETRIABLE_STATUSES,
                        methods: RETRIABLE_METHODS,
                        exceptions: RETRIABLE_EXCEPTIONS
      end

      # @param builder [Faraday::Connection] The connection being built
      # @param configuration [AbacatePay::Configuration] The active configuration
      # @return [void]
      def configure_logging(builder, configuration)
        return unless configuration.logger

        builder.response :logger, configuration.logger, headers: true, bodies: false do |logger|
          # Faraday renders header values inspected, so the token appears as
          #   Authorization: "Bearer abc_live_..."
          # Both spellings are filtered so a change in that formatting cannot
          # silently start leaking the credential.
          logger.filter(/(Authorization:\s*")Bearer\s+[^"]*(")/i, '\1Bearer [REDACTED]\2')
          logger.filter(/(Authorization:\s*)Bearer\s+\S+/i, '\1Bearer [REDACTED]')
        end
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
      rescue JSON::ParserError
        raise ApiError, "Request error: #{error.message}"
      end
    end
  end
end
