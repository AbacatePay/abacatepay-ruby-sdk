# frozen_string_literal: true

module AbacatePay
  module Enums
    module Webhooks
      class EventTypes
        CHECKOUT_COMPLETED = "checkout.completed"
        CHECKOUT_REFUNDED = "checkout.refunded"
        CHECKOUT_DISPUTED = "checkout.disputed"
        TRANSPARENT_COMPLETED = "transparent.completed"
        TRANSPARENT_REFUNDED = "transparent.refunded"
        TRANSPARENT_DISPUTED = "transparent.disputed"
        SUBSCRIPTION_COMPLETED = "subscription.completed"
        SUBSCRIPTION_RENEWED = "subscription.renewed"
        SUBSCRIPTION_CANCELLED = "subscription.cancelled"

        # Recurring charge failed, the dunning signal. Without handling this,
        # a failing subscription looks identical to a healthy one.
        SUBSCRIPTION_PAYMENT_FAILED = "subscription.payment_failed"

        SUBSCRIPTION_TRIAL_STARTED = "subscription.trial_started"
        TRANSFER_COMPLETED = "transfer.completed"
        TRANSFER_FAILED = "transfer.failed"
        PAYOUT_COMPLETED = "payout.completed"
        PAYOUT_FAILED = "payout.failed"

        def self.values
          [
            CHECKOUT_COMPLETED, CHECKOUT_REFUNDED, CHECKOUT_DISPUTED,
            TRANSPARENT_COMPLETED, TRANSPARENT_REFUNDED, TRANSPARENT_DISPUTED,
            SUBSCRIPTION_COMPLETED, SUBSCRIPTION_RENEWED, SUBSCRIPTION_CANCELLED,
            SUBSCRIPTION_PAYMENT_FAILED, SUBSCRIPTION_TRIAL_STARTED,
            TRANSFER_COMPLETED, TRANSFER_FAILED,
            PAYOUT_COMPLETED, PAYOUT_FAILED
          ]
        end

        def self.valid?(value)
          values.include?(value)
        end

        def self.validate!(value)
          raise ArgumentError, "Invalid webhook event type: #{value}" unless valid?(value)

          value
        end
      end
    end
  end
end
