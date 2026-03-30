# AbacatePay Ruby SDK

Ruby SDK for [AbacatePay](https://www.abacatepay.com/) payment gateway. Works with any Ruby application (Rails, Sinatra, Hanami, plain Ruby).

## Installation

Add to your Gemfile:

```ruby
gem 'abacatepay-ruby'
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install abacatepay-ruby
```

## Configuration

```ruby
AbacatePay.configure do |config|
  config.api_token = ENV['ABACATEPAY_TOKEN']
  config.environment = :sandbox # or :production
  config.timeout = 30 # optional, in seconds
end
```

For Rails, place this in `config/initializers/abacatepay.rb`.

## Usage

The SDK provides a convenience facade for all resources:

```ruby
AbacatePay.customers.list
AbacatePay.checkouts.create(data)
AbacatePay.products.get(id)
```

Or instantiate clients directly:

```ruby
client = AbacatePay::Clients::CheckoutClient.new
client.list
```

All `list` methods accept optional pagination parameters:

```ruby
AbacatePay.customers.list(limit: 10, after: "cursor_abc")
```

---

## Resources

### Customers

```ruby
# List all customers
AbacatePay.customers.list

# Get a customer by ID
AbacatePay.customers.get("cust_123")

# Create a customer
AbacatePay.customers.create(
  AbacatePay::Resources::Customers.new(
    metadata: AbacatePay::Resources::Customers::Metadata.new(
      name: 'Abacate Lover',
      cellphone: '01912341234',
      email: 'lover@abacate.com',
      tax_id: '13827826837'
    )
  )
)

# Delete a customer
AbacatePay.customers.delete("cust_123")
```

### Products

```ruby
# List all products
AbacatePay.products.list

# Get a product
AbacatePay.products.get("prod_123")

# Create a product
AbacatePay.products.create(
  AbacatePay::Resources::Products.new(
    externalId: 'my-product-1',
    name: 'Monthly Plan',
    price: 2990, # R$ 29.90 in cents
    currency: 'BRL',
    description: 'Access to all features',
    cycle: 'MONTHLY' # WEEKLY, MONTHLY, SEMIANNUALLY, ANNUALLY or nil for one-time
  )
)

# Delete a product
AbacatePay.products.delete("prod_123")
```

### Coupons

```ruby
# List all coupons
AbacatePay.coupons.list

# Get a coupon
AbacatePay.coupons.get("coup_123")

# Create a coupon
AbacatePay.coupons.create(
  AbacatePay::Resources::Coupons.new(
    code: 'SAVE20',
    discount: 20,
    discountKind: 'PERCENTAGE', # or 'FIXED'
    maxRedeems: 100
  )
)

# Toggle coupon active/inactive
AbacatePay.coupons.toggle("coup_123")

# Delete a coupon
AbacatePay.coupons.delete("coup_123")
```

### Checkouts

```ruby
# List checkouts (with optional filters)
AbacatePay.checkouts.list
AbacatePay.checkouts.list(status: "PAID", email: "user@example.com")

# Get a checkout
AbacatePay.checkouts.get("chk_123")

# Create a checkout with a new customer
AbacatePay.checkouts.create(
  AbacatePay::Resources::Checkouts.new(
    frequency: 'ONE_TIME',
    methods: ['PIX', 'CARD'],
    products: [
      AbacatePay::Resources::Billings::Product.new(
        external_id: 'abc_123',
        name: 'Product A',
        description: 'Description of product A',
        quantity: 1,
        price: 100
      )
    ],
    metadata: AbacatePay::Resources::Billings::Metadata.new(
      return_url: 'https://yoursite.com/cancel',
      completion_url: 'https://yoursite.com/success'
    ),
    customer: AbacatePay::Resources::Customers.new(
      metadata: AbacatePay::Resources::Customers::Metadata.new(
        name: 'Abacate Lover',
        cellphone: '01912341234',
        email: 'lover@abacate.com',
        tax_id: '13827826837'
      )
    )
  )
)

# Create a checkout with an existing customer
AbacatePay.checkouts.create(
  AbacatePay::Resources::Checkouts.new(
    frequency: 'ONE_TIME',
    methods: ['PIX'],
    products: [...],
    customer: AbacatePay::Resources::Customers.new(id: 'cust_DEbpqcN...')
  )
)

# Create a reusable payment link
AbacatePay.checkouts.create(
  AbacatePay::Resources::Checkouts.new(
    frequency: 'MULTIPLE_PAYMENTS',
    methods: ['PIX'],
    products: [...]
  )
)
```

### Subscriptions

```ruby
# List subscriptions
AbacatePay.subscriptions.list

# Create a subscription (requires exactly 1 product with a cycle)
AbacatePay.subscriptions.create(
  AbacatePay::Resources::Subscriptions.new(
    methods: ['PIX'],
    customer: AbacatePay::Resources::Customers.new(id: 'cust_123'),
    products: [
      AbacatePay::Resources::Billings::Product.new(
        external_id: 'plan-monthly',
        name: 'Monthly Plan',
        price: 2990,
        quantity: 1
      )
    ]
  )
)
```

### PIX Transparent Payments (QR Code)

```ruby
# List QR codes
AbacatePay.transparents.list

# Generate a PIX QR code
AbacatePay.transparents.create(
  AbacatePay::Resources::Transparents.new(
    amount: 1000, # R$ 10.00
    description: 'Payment for order #123',
    expiresIn: 3600
  )
)

# Check payment status
AbacatePay.transparents.check("tr_123")

# Simulate payment (dev mode only)
AbacatePay.transparents.simulate_payment("tr_123")
```

### PIX Transfers

```ruby
# List transfers
AbacatePay.pix.list

# Get a transfer
AbacatePay.pix.get("pix_123")

# Send PIX to an external key
AbacatePay.pix.send_pix(
  AbacatePay::Resources::PixTransfers.new(
    amount: 500, # R$ 5.00
    externalId: 'transfer-001',
    description: 'Payment to vendor',
    key: '12345678900',
    keyType: 'CPF' # CPF, CNPJ, PHONE, EMAIL, RANDOM, BR_CODE
  )
)
```

### Payouts

```ruby
# List payouts
AbacatePay.payouts.list

# Get a payout
AbacatePay.payouts.get("pay_123")

# Create a withdrawal (minimum R$ 3.50)
AbacatePay.payouts.create(
  AbacatePay::Resources::Payouts.new(
    amount: 5000, # R$ 50.00
    externalId: 'withdrawal-001',
    description: 'Monthly withdrawal'
  )
)
```

### Store

```ruby
# Get account details (balance info)
store = AbacatePay.store.get
store.balance.available # => 10000
store.balance.pending   # => 500
store.balance.blocked   # => 0

# Get merchant info
AbacatePay.store.merchant_info

# Get MRR metrics
AbacatePay.store.mrr

# Get revenue by period
AbacatePay.store.revenue(start_date: '2026-01-01', end_date: '2026-03-30')
```

---

## Webhooks

Verify webhook signatures and parse events:

```ruby
payload = request.body.read
signature = request.headers['X-Webhook-Signature']
secret = ENV['ABACATEPAY_WEBHOOK_SECRET']

# Verify signature (raises AbacatePay::Webhooks::SignatureError if invalid)
AbacatePay::Webhooks.verify!(payload: payload, signature: signature, secret: secret)

# Or use the boolean version
if AbacatePay::Webhooks.valid?(payload: payload, signature: signature, secret: secret)
  event = AbacatePay::Webhooks.parse(payload)

  case event.type
  when 'checkout.completed'
    # handle successful payment
  when 'checkout.refunded'
    # handle refund
  when 'subscription.renewed'
    # handle subscription renewal
  end
end
```

### Webhook event types

| Category | Events |
|---|---|
| Checkout | `checkout.completed`, `checkout.refunded`, `checkout.disputed` |
| Transparent | `transparent.completed`, `transparent.refunded`, `transparent.disputed` |
| Subscription | `subscription.completed`, `subscription.renewed`, `subscription.cancelled` |
| Transfer | `transfer.completed`, `transfer.failed` |
| Payout | `payout.completed`, `payout.failed` |

---

## Enums

Available enum values for validation:

| Enum | Values |
|---|---|
| `Billings::Methods` | `PIX`, `CARD` |
| `Billings::Frequencies` | `ONE_TIME`, `WEEKLY`, `MONTHLY`, `SEMIANNUALLY`, `ANNUALLY`, `MULTIPLE_PAYMENTS` |
| `Billings::Statuses` | `PENDING`, `EXPIRED`, `CANCELLED`, `PAID`, `REFUNDED` |
| `Products::Cycles` | `WEEKLY`, `MONTHLY`, `SEMIANNUALLY`, `ANNUALLY` |
| `Coupons::Statuses` | `ACTIVE`, `INACTIVE`, `EXPIRED` |
| `Coupons::DiscountKinds` | `PERCENTAGE`, `FIXED` |
| `Pix::KeyTypes` | `CPF`, `CNPJ`, `PHONE`, `EMAIL`, `RANDOM`, `BR_CODE` |
| `Transfers::Statuses` | `PENDING`, `COMPLETE`, `CANCELLED`, `EXPIRED`, `REFUNDED`, `FAILED` |
| `Payouts::Statuses` | `PENDING`, `COMPLETE`, `CANCELLED`, `EXPIRED`, `REFUNDED` |

---

## Error Handling

```ruby
begin
  AbacatePay.checkouts.create(data)
rescue AbacatePay::ConfigurationError => e
  # API token missing or invalid environment
rescue AbacatePay::ApiError => e
  # API request failed
rescue AbacatePay::Webhooks::SignatureError => e
  # Invalid webhook signature
end
```

---

## Documentation

Official API documentation: https://abacatepay.readme.io/reference

## Contribution

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a branch: `git checkout -b feature/your-feature-name`
3. Make your changes and commit
4. Push to your branch: `git push origin feature/your-feature-name`
5. Open a pull request

Please ensure your code:

- Follows Ruby style guidelines
- Includes appropriate tests
- Passes all tests (`bundle exec rspec`)
- Passes style checks (`bundle exec rubocop`)

## License

MIT
