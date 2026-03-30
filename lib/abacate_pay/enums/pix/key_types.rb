# frozen_string_literal: true

module AbacatePay
  module Enums
    module Pix
      class KeyTypes
        CPF = "CPF"
        CNPJ = "CNPJ"
        PHONE = "PHONE"
        EMAIL = "EMAIL"
        RANDOM = "RANDOM"
        BR_CODE = "BR_CODE"

        def self.values
          [CPF, CNPJ, PHONE, EMAIL, RANDOM, BR_CODE]
        end

        def self.valid?(value)
          values.include?(value)
        end

        def self.validate!(value)
          raise ArgumentError, "Invalid PIX key type: #{value}" unless valid?(value)
          value
        end
      end
    end
  end
end
