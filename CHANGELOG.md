# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.1] - 2026-08-06

Every fix below was found by running the SDK against the live sandbox and a
real Rails application, not against its own test suite.

### Fixed

- **`gem "abacatepay-ruby"` did not load the SDK.** Bundler requires a gem by
  its own name, so Rails called `require "abacatepay-ruby"`, and the entry
  point was `lib/abacate_pay.rb`. The require failed, but the gemspec had
  already defined `AbacatePay` with nothing but `VERSION` in it, so the first
  call raised `undefined method 'configure' for module AbacatePay` instead of a
  missing-constant error. Every Rails user had to discover `require:
  "abacate_pay"` on their own. There is now an entry point matching the gem
  name.
- **Customer responses dropped every field except the id.** The API returns
  `name`, `email`, `cellphone` and `taxId` at the top level of the customer
  object with an empty `metadata`; the resource only mapped a nested
  `metadata`, so `customers.list` and `customers.get` returned objects with
  nothing usable and `customer.metadata.name` was always nil. The fields are
  exposed directly now, and `metadata` keeps answering for code written against
  the previous interface.
- **`AbacatePay.store.get` always failed.** The API serves this as
  `stores/get`, plural. The singular path documented in the reference answers
  HTTP 400.

### Changed

- The README no longer implies `has_more?` is always available. List responses
  only carry pagination metadata when the API sends it; otherwise they are
  plain Arrays, exactly as before.

## [1.2.0] - 2026-08-05

### Fixed

- **Webhook signature verification rejected every genuine delivery.** The SDK
  compared against `OpenSSL::HMAC.hexdigest`, but AbacatePay sends the HMAC
  base64-encoded. The [security
  spec](https://docs.abacatepay.com/pages/webhooks/security) and its Node,
  Python and Go samples all use base64. `verify!` therefore failed every real
  webhook while accepting a hex signature nobody sends, making webhook
  verification inoperative since it was introduced. Reported by @danieldenis01
  in #6, found while building a `pay-rails/pay` adapter against the sandbox and
  production, along with the three fixes above.
- **`qr_code` and `qr_code_image` always returned nil for transparent PIX.** The
  API sends the copy-and-paste payload as `brCode` and the image as
  `brCodeBase64`; the readers looked for the older `qrCode`/`qrCodeImage`
  spelling. Both are accepted now, preferring `qr*` when present. `platform_fee`
  and `receipt_url` were missing entirely.
- **`simulate_payment` sent the id in the body.** The API reads it from the
  query string on this endpoint, like `check`, and body-only requests fail with
  "Expected property 'id'".
- **Optional fields were sent as explicit nulls.** The API rejects
  `{"cellphone": null}` with HTTP 400 `Expected property 'cellphone' to be
  string but found: null`, and payload builders emit nils for anything the
  caller left unset. Payloads are now compacted recursively at the request
  boundary, so this cannot be forgotten by a future endpoint. Also reported in
  #6; the fix covers `products`, `coupons`, `payouts`, `pix` and
  `subscriptions`, which had the same defect.

### Added

- `AbacatePay::Webhooks::PUBLIC_KEY`, the fixed key AbacatePay signs with, now
  the default for `secret:`. It is public and global, so it proves body
  integrity only: anyone can compute a valid signature with it.
- `AbacatePay::Webhooks.verify_secret!(received:, expected:)` for the
  `webhookSecret` query parameter, which is what actually authenticates the
  origin. The docs instruct using both mechanisms together; the SDK previously
  offered only the HMAC half.

## [1.1.0] - 2026-08-05

### Added

- **BOLETO support.** The method was rejected outright by the `Billings::Methods`
  enum even though it is a first-class payment method in the v2 API. Adds the
  enum value, the boleto-only `due_date`/`interest`/`fine` fields on checkouts,
  and a `method:` argument on `TransparentClient#create` (which previously
  hard-coded PIX). Boleto responses now expose `bar_code`, `url`, `br_code`,
  `br_code_base64` and `expires_at`.
- **Cursor pagination.** List endpoints cap at 100 items and report `hasMore`
  plus a cursor; the SDK discarded that metadata, making record 101
  unreachable. `list` now returns an `AbacatePay::Collection`. It is Enumerable and
  Array-compatible, so existing code is unaffected, and it carries `has_more?`
  and `next_cursor`. `each_page` and `auto_paging_each` walk every page.
- **Retries with exponential backoff and jitter** on 429 and 5xx, configurable
  via `config.max_retries` (default 2). Only idempotent methods are retried;
  POST never is, because repeating `checkouts/create` after a timeout could
  charge a customer twice and the API exposes no idempotency key.
- **Optional request logging** via `config.logger`, with the bearer token
  redacted and bodies never logged.
- `SubscriptionClient#change_plan` and `#record_usage`: the last two of the 45
  documented v2 endpoints. All 45 are now covered.
- `subscription.payment_failed` and `subscription.trial_started` webhook event
  types. `payment_failed` is the dunning signal.
- Checkout fields the v2 API accepts but the SDK never sent: `max_installments`
  (nested under `card`), `up_sell_product_id` and `custom_metadata`.
- A `User-Agent` identifying the SDK and Ruby version.

### Fixed

- `Webhooks.parse` aside, malformed API responses raised `JSON::ParserError`
  and a missing `data` field raised `KeyError`; both are now `ApiError`.

### Changed

- `BillingClient`'s deprecation warning now states that its `/billings/*`
  endpoints do not exist on either API version, so every call fails. It will be
  removed in 2.0.0.

### Corrected

- The 1.0.0 notes stated that the v1 API "has been retired and answers Not found
  for every path". That is wrong: v1 is still served, under a different dialect.
  It uses singular paths (`/v1/billing/`, `/v1/customer/`) and different
  resource names (`pixQrCode`). The original diagnosis tested v2-shaped paths against
  `/v1`. The fix itself stands: this SDK only ever spoke v2's dialect, so 10 of
  the 12 paths it calls do not exist on v1 and routing there produced 404s.

## [1.0.0] - 2026-08-05

First stable release. The public surface is now covered by CI on four Ruby
versions and will not change without a major bump.

### Added

- Full API coverage: checkouts, coupons, customers, payouts, PIX transfers,
  products, store, subscriptions and transparent checkout.
- `AbacatePay::Webhooks.construct_event`, which verifies the signature and parses the
  body in a single call, so an unverified payload cannot be acted on.
- `AbacatePay::Webhooks::PayloadError` for malformed or non-object webhook bodies.
- `PaymentLinkClient` (`AbacatePay.payment_links`) for reusable multi-payment links.
- `WebhookClient` (`AbacatePay.webhook_endpoints`) for webhook endpoint registration,
  with local HTTPS validation so a bad endpoint fails before the round trip.
- `CheckoutClient#refund`, `TransparentClient#refund`, `PaymentLinkClient#refund`.
  Refunds were previously impossible through the SDK.
- `SubscriptionClient#cancel`. A subscription created through the SDK could not
  be cancelled through it.
- CI workflow running the suite on Ruby 3.2, 3.3, 3.4 and 4.0, plus RuboCop, a
  dependency audit and a gem build check on every pull request.
- Request-contract specs that let the client build its own connection, asserting
  the real endpoint path, bearer token, timeout and outgoing JSON body. The
  existing client specs injected their own Faraday connection, so a wrong
  endpoint path could not fail them.
- Coverage measurement: simplecov has been a declared dependency since 0.1.0
  without ever being loaded. Line coverage is now 99.13% with a 90% floor.
- Dependabot for bundler and GitHub Actions.

### Fixed

- **The SDK routed to a retired API.** `api_url` derived the version from the
  token prefix and fell back to `/v1` for any format it did not recognise. The
  v1 prefix has been retired and answers
  `{"success":false,"data":null,"error":"Not found"}` on every path, so anyone
  holding a token in an older format failed 100% of calls with a message that
  did not point at the cause. There is one base URL now:
  `https://api.abacatepay.com/v2`.
- **Three source files were missing from the built gem.** The gemspec builds its
  file list from `git ls-files`, so a file nobody had staged was silently
  dropped from the package; because the manifests require every component
  explicitly, `require "abacate_pay"` then raised `LoadError` on the installed
  gem while the whole suite stayed green against the working tree. A packaging
  spec now asserts that every file under `lib/` ships.
- **Using the SDK before calling `configure` raised `NoMethodError`.** The most
  common first-run mistake surfaced as `undefined method 'api_url' for nil` from
  inside the client instead of naming the missing call. It is now a
  `ConfigurationError` that says what to do.
- **Assigning `AbacatePay.configuration` directly left stale clients behind.**
  `configure` discarded memoized clients but the raw writer did not, so a client
  built against replaced credentials outlived them.
- **Webhook verification crashed on a missing signature header.** A request
  without `X-Webhook-Signature` reached `secure_compare` as `nil` and raised
  `NoMethodError`, so `valid?` returned neither `true` nor `false` and the
  endpoint returned a server error instead of rejecting the request. Missing and
  empty signatures, plus a missing secret, are now `SignatureError`.
- **`Webhooks.parse` leaked parser internals.** Malformed JSON raised
  `JSON::ParserError` and a non-object JSON body raised `TypeError`; both now
  raise `PayloadError`.
- **`config.timeout` was dead configuration.** It was documented and settable but
  never reached Faraday, so a hung gateway blocked the calling thread forever.
  It now sets both the read and open timeout.
- **Changing the token at runtime had no effect.** Clients were memoized on first
  use and never rebuilt, so `AbacatePay.configure` after a first API call kept
  sending the previous bearer token. `configure` now discards memoized clients.
- `Configuration#api_url` was declared twice, as an `attr_reader` and as a
  method. The dead reader has been removed.
- `CustomerClient#get` and `#delete` had no test coverage at all.
- The `customer` and `billing` specs stubbed singular endpoint paths while the
  clients call the plural ones; the specs never noticed because they bypassed
  connection building.
- Component loading no longer depends on a `Dir` glob whose correctness rested on
  alphabetical ordering placing `client.rb` before its subclasses. The three
  manifest files were also missing every class added after 0.1.0.

### Security

- **faraday is now `~> 2.14, >= 2.14.3`**, excluding CVE-2026-54297 (High): an
  uncontrolled recursion in `NestedParamsEncoder` allowing stack-exhaustion DoS
  via deeply nested query parameters. The previous `~> 2.9` constraint let
  consumers resolve to a vulnerable version.
- Webhook handling no longer crashes on unauthenticated input (see Fixed).

### Changed

- **BREAKING: `required_ruby_version` is now `>= 3.2.0`** (was `>= 2.6.0`). The
  old floor was never installable: faraday 2.x requires Ruby 3.0 or newer, so
  no working installation is losing support, but a `bundle update` on Ruby 2.6
  or 3.1 will now refuse to resolve instead of failing later.
- **`config.environment` is deprecated and now warns.** It was declared,
  defaulted, and validated, but read by nothing. Per AbacatePay's own
  documentation the environment is decided by the API key (Dev mode keys
  simulate transactions), so the setting could never have worked. It is kept as
  an accepted no-op so existing initializers keep loading.
- `validate!` no longer rejects unknown `environment` values, and now rejects an
  empty or whitespace-only token.
- Releases publish from a `v*` tag instead of every push to `main`, and verify
  that the tag matches `AbacatePay::VERSION` before publishing.
- Publishing uses RubyGems Trusted Publishing (OIDC) instead of a long-lived API
  key written to `~/.gem/credentials`.
- `rubygems_mfa_required` is enabled on the gem.

### Removed

- Publishing to GitHub Packages. The step never executed successfully in any run
  and nothing consumed the gem from that registry.
- `sig/abacatepay/rails.rbs`. Leftover `bundle gem` scaffolding declaring an
  `Abacatepay::Rails` module that does not exist in this codebase, and that was
  shipping inside the published gem, where a type checker would read it.

## [0.1.0] - 2024-12-13

- Initial release

[1.2.1]: https://github.com/AbacatePay/abacatepay-ruby-sdk/releases/tag/v1.2.1
[1.2.0]: https://github.com/AbacatePay/abacatepay-ruby-sdk/releases/tag/v1.2.0
[1.1.0]: https://github.com/AbacatePay/abacatepay-ruby-sdk/releases/tag/v1.1.0
[1.0.0]: https://github.com/AbacatePay/abacatepay-ruby-sdk/releases/tag/v1.0.0
[0.1.0]: https://github.com/AbacatePay/abacatepay-ruby-sdk/releases/tag/v0.1.0
