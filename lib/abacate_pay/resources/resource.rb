# frozen_string_literal: true

module AbacatePay
  module Resources
    # Base class for resources in the AbacatePay system.
    class Resource
      private

      # Initialize a DateTime object from a string or DateTime
      #
      # @param value [String, DateTime] The value to initialize
      # @return [DateTime, nil] The initialized DateTime object or nil
      # @raise [ArgumentError] If the value is invalid
      def initialize_date_time(value)
        return nil if value.nil?
        return value.clone if value.is_a?(DateTime)
        return nil if value.empty?

        DateTime.parse(value)
      rescue Date::Error
        raise ArgumentError, "Invalid datetime value: #{value}"
      end

      # Initialize an enum from a string or enum object.
      #
      # Unknown values pass through with a warning rather than raising. This
      # method runs while parsing API responses, and AbacatePay adds statuses
      # over time: rejecting an unrecognised one would turn every new value
      # into a crash inside `list` and `get` for every integration at once.
      # That happened with the coupon status `DISABLED` and the payment-link
      # status `ACTIVE`, neither of which the SDK knew about.
      #
      # Use {AbacatePay::Enums} `validate!` directly when you want a hard
      # failure on a value you are about to send.
      #
      # @param enum_class [Class] The enum class to initialize
      # @param value [String, Object] The value to initialize
      # @return [Object, nil] The value, validated when known
      def initialize_enum(enum_class, value)
        return nil if value.nil? || value.empty?
        return value if enum_class.valid?(value)

        warn "[AbacatePay] unknown #{enum_class.name.split("::").last} value #{value.inspect}. " \
             "Passing it through; upgrade the gem if this is a new API value."
        value
      end

      # Initialize a resource from a hash or resource object
      #
      # @param resource_class [Class] The resource class to initialize
      # @param value [Hash, Object] The value to initialize
      # @return [Object, nil] The initialized resource or nil
      # @raise [ArgumentError] If the value is invalid
      def initialize_resource(resource_class, value)
        return nil if value.nil?
        return value.clone if value.is_a?(resource_class)
        return nil if value.respond_to?(:empty?) && value.empty?

        unless value.is_a?(Hash)
          raise ArgumentError, "Invalid resource value. Expected Hash or #{resource_class}, got #{value.class}"
        end

        resource_class.new(value)
      end

      # Default value processor, returns the value as-is.
      # Subclasses override this to handle enums, datetimes, and nested resources.
      #
      # @param _property [String] The property name
      # @param value [Object] The raw value
      # @return [Object] The processed value
      def process_value(_property, value)
        value
      end

      # Fill the object with data
      #
      # @param data [Hash] The data to fill with
      # @return [void]
      def fill(data)
        # Some endpoints answer a successful call with no payload, so the
        # resource is built from nil. An empty object beats a NoMethodError.
        return if data.nil?

        data.each do |key, value|
          property = camel_to_snake(key)
          next unless respond_to?("#{property}=", true)

          send("#{property}=", process_value(property, value))
        end
      end

      # Convert camelCase to snake_case
      #
      # @param str [String] The string to convert
      # @return [String] The converted string
      def camel_to_snake(str)
        str.to_s
           .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
           .gsub(/([a-z\d])([A-Z])/, '\1_\2')
           .downcase
      end

      # Convert snake_case to camelCase
      #
      # @param str [String] The string to convert
      # @return [String] The converted string
      def snake_to_camel(str)
        str.split("_")
           .map.with_index { |word, i| i.zero? ? word : word.capitalize }
           .join
      end

      protected

      # Convert the resource to a hash
      #
      # @return [Hash] The hash representation
      def to_hash
        instance_variables.each_with_object({}) do |var, hash|
          next if var.to_s.start_with?("@__")

          value = instance_variable_get(var)
          key = snake_to_camel(var.to_s.delete("@"))

          hash[key] = case value
                      when DateTime
                        value.iso8601
                      when Resource
                        value.to_hash
                      when Module
                        value.respond_to?(:value) ? value.value : value
                      when Array
                        value.map { |v| v.respond_to?(:to_hash) ? v.to_hash : v }
                      else
                        value
                      end
        end.compact
      end
    end
  end
end
