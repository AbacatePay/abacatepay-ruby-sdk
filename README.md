# AbacatePay SDK for Ruby on Rails

## 💻 Installation

Add this line to your application's Gemfile:

```ruby
gem 'abacatepay-ruby'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install abacatepay-ruby
```

## 🔧 Configuration

Configure your API token and environment in an initializer:

```ruby
# config/initializers/abacatepay.rb
AbacatePay.configure do |config|
  config.api_token = ENV['ABACATEPAY_TOKEN']
  config.environment = :sandbox # or :production
end
```

## 🌟 Resources

### Billing

**Initialize the Billing Client**

```ruby
billing_client = AbacatePay::Clients::BillingClient.new
```

**List Billings**

Retrieve a list of all billings:

```ruby
billing_client.list
```

**Create a Billing**

To create a billing, use the following code:

```ruby
billing_client.create(
  AbacatePay::Resources::Billings.new(
    frequency: AbacatePay::Enums::Billings::Frequencies::ONE_TIME,
    methods: [AbacatePay::Enums::Billings::Methods::PIX],
    products: [
      AbacatePay::Resources::Billings::Product.new(
        external_id: 'abc_123',
        name: 'Product A',
        description: 'Description of product A',
        quantity: 1,
        price: 100 # Price in cents
      )
    ],
    metadata: AbacatePay::Resources::Billings::Metadata.new(
      return_url: 'https://www.abacatepay.com',
      completion_url: 'https://www.abacatepay.com'
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
```

Alternatively, you can use a previously created customer by specifying their ID:

```ruby
AbacatePay::Resources::Customers.new(
  id: 'cust_DEbpqcN...'
)
```

### Customer

**Initialize the Customer Client**

```ruby
customer_client = AbacatePay::Clients::CustomerClient.new
```

**List Customers**

Retrieve a list of all customers:

```ruby
customer_client.list
```

**Create a Customer**

To create a customer, use the following code:

```ruby
customer_client.create(
  AbacatePay::Resources::Customers.new(
    metadata: AbacatePay::Resources::Customer::Metadata.new(
      name: 'Abacate Lover',
      cellphone: '01912341234',
      email: 'lover@abacate.com',
      tax_id: '13827826837'
    )
  )
)
```

## 📚 Documentation

For detailed information about the API and SDK, refer to the official documentation:
https://abacatepay.readme.io/reference

## 🤝 Contribution

Contributions are welcome! If you wish to contribute:

1. Fork the repository
2. Create a new branch for your feature or fix:

```bash
git checkout -b feature/your-feature-name
```

3. Make your changes and commit them:

```bash
git commit -m "Add your detailed commit message here"
```

4. Push to your branch:

```bash
git push origin feature/your-feature-name
```

5. Open a pull request with a clear description of your changes

Please ensure your code:

- Includes proper documentation
- Follows Ruby style guidelines
- Includes appropriate tests
- Passes all existing tests (bundle exec rspec)
- Passes code style checks (bundle exec rubocop)

### Happy coding! 🚀