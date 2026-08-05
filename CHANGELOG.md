# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Full API coverage: checkouts, coupons, customers, payouts, PIX transfers,
  products, store, subscriptions and transparent checkout.
- `AbacatePay::Webhooks.construct_event` — verifies the signature and parses the
  body in a single call, so an unverified payload cannot be acted on.
- `AbacatePay::Webhooks::PayloadError` for malformed or non-object webhook bodies.
- `PaymentLinkClient` (`AbacatePay.payment_links`) — reusable multi-payment links.
- `WebhookClient` (`AbacatePay.webhook_endpoints`) — webhook endpoint registration,
  with local HTTPS validation so a bad endpoint fails before the round trip.
- `CheckoutClient#refund`, `TransparentClient#refund`, `PaymentLinkClient#refund` —
  refunds were previously impossible through the SDK.
- `SubscriptionClient#cancel` — a subscription created through the SDK could not
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
  empty signatures — and a missing secret — are now `SignatureError`.
- **`Webhooks.parse` leaked parser internals.** Malformed JSON raised
  `JSON::ParserError` and a non-object JSON body raised `TypeError`; both now
  raise `PayloadError`.
- **`config.timeout` was dead configuration.** It was documented and settable but
  never reached Faraday, so a hung gateway blocked the calling thread forever.
  It now sets both the read and open timeout.
- **Changing the token at runtime had no effect.** Clients were memoized on first
  use and never rebuilt, so `AbacatePay.configure` after a first API call kept
  sending the previous bearer token. `configure` now discards memoized clients.
- `Configuration#api_url` was declared twice — as an `attr_reader` and as a
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

- **`config.environment` is deprecated and now warns.** It was declared,
  defaulted, and validated, but read by nothing. Per AbacatePay's own
  documentation the environment is decided by the API key — Dev mode keys
  simulate transactions — so the setting could never have worked. It is kept as
  an accepted no-op so existing initializers keep loading.
- `validate!` no longer rejects unknown `environment` values, and now rejects an
  empty or whitespace-only token.
- **`required_ruby_version` is now `>= 3.2.0`** (was `>= 2.6.0`). The old floor
  was never installable: faraday 2.x requires Ruby 3.0 or newer.
- Releases publish from a `v*` tag instead of every push to `main`, and verify
  that the tag matches `AbacatePay::VERSION` before publishing.
- Publishing uses RubyGems Trusted Publishing (OIDC) instead of a long-lived API
  key written to `~/.gem/credentials`.
- `rubygems_mfa_required` is enabled on the gem.

### Removed

- Publishing to GitHub Packages. The step never executed successfully in any run
  and nothing consumed the gem from that registry.
- `sig/abacatepay/rails.rbs`. Leftover `bundle gem` scaffolding declaring an
  `Abacatepay::Rails` module that does not exist in this codebase — and it was
  shipping inside the published gem, where a type checker would read it.

## [0.1.0] - 2024-12-11

- Initial release
