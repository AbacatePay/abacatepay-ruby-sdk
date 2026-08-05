<div align="center">

# AbacatePay Ruby SDK

SDK oficial da **AbacatePay** para integrar pagamentos via **PIX** de forma simples, segura e idiomática em Ruby.

O [`abacatepay-ruby`](https://rubygems.org/gems/abacatepay-ruby) é um **wrapper versionado de alto nível** sobre a API da AbacatePay, focado em **DX**, **verificação segura de webhooks** e **erros tipados**.

<img src="https://res.cloudinary.com/dkok1obj5/image/upload/v1767631413/avo_clhmaf.png" width="100%" alt="AbacatePay Open Source"/>

Funciona em qualquer aplicação Ruby: Rails, Sinatra, Hanami ou Ruby puro.

Referência completa da API [aqui](https://abacatepay.readme.io/reference).

## Requisitos

Ruby **3.2 ou superior**. Testado em 3.2, 3.3, 3.4 e 4.0.

## Instalação

</div>

```bash
bundle add abacatepay-ruby
```

<div align="center">

Ou adicione ao seu `Gemfile`:

</div>

```ruby
gem 'abacatepay-ruby'
```

<div align="center">

## Uso básico

</div>

```ruby
AbacatePay.configure do |config|
  config.api_token  = ENV['ABACATEPAY_TOKEN']
  config.timeout    = 30      # opcional, segundos (default 30)
  config.max_retries = 2      # opcional, retry em 429/5xx (default 2, 0 desliga)
  config.logger     = Rails.logger # opcional, token é redigido
end
```

<div align="center">

Nunca utilize sua API key diretamente no código.
**Sempre use variáveis de ambiente**.

Em Rails, coloque isso em `config/initializers/abacatepay.rb`.

Trocar o token em runtime tem efeito imediato: os clients são reconstruídos a cada `configure`.

### Criando uma cobrança

</div>

```ruby
checkout = AbacatePay.checkouts.create(
  AbacatePay::Resources::Checkouts.new(
    frequency: 'ONE_TIME',
    methods: ['PIX'],
    products: [
      AbacatePay::Resources::Billings::Product.new(
        external_id: 'prod_123',
        name: 'Product A',
        quantity: 1,
        price: 100
      )
    ],
    customer: AbacatePay::Resources::Customers.new(id: 'cust_123')
  )
)
```

<div align="center">

### Procure por alguns clientes

</div>

```ruby
customers = AbacatePay.customers.list(limit: 25)
```

<div align="center">

Todos os métodos `list` aceitam parâmetros de paginação e filtro opcionais:

</div>

```ruby
AbacatePay.customers.list(limit: 10, after: 'cursor_abc')
AbacatePay.checkouts.list(status: 'PAID', email: 'user@example.com')
```

<div align="center">

Listas retornam no máximo 100 itens. O resultado é uma `Collection`, que funciona como Array e ainda carrega o cursor:

</div>

```ruby
page = AbacatePay.customers.list
page.first.id     # funciona como Array
page.has_more?    # => true
page.next_cursor  # => "cust_abc123"

# Para percorrer tudo sem lidar com cursor:
AbacatePay.customers.auto_paging_each { |customer| puts customer.id }
AbacatePay.customers.each_page { |page| puts page.size }
```

<div align="center">

## Versionamento

O SDK fala **exclusivamente a v2**, em `https://api.abacatepay.com/v2`. A v1 ainda existe para integrações legadas, mas usa outro dialeto (caminhos no singular como `/v1/billing/`, `/v1/customer/`) que este SDK nunca implementou. Se você precisa da v1, chame a API diretamente.

O ambiente (dev mode x produção) é definido **pela chave de API**, não por configuração: chaves de Dev mode geram transações simuladas. Por isso `config.environment` não faz nada. Ela continua aceita para não quebrar initializers existentes, mas emite aviso de depreciação.

O `BillingClient` também está descontinuado, substituído pelo `CheckoutClient`. Seus endpoints `/billings/*` não existem em nenhuma versão da API: toda chamada falha. Será removido na 2.0.0:

</div>

```
[DEPRECATION] BillingClient calls /billings/* endpoints that do not exist on the
AbacatePay API, every request will fail. Use AbacatePay.checkouts instead.
This class will be removed in 2.0.0.
```

<div align="center">

## Tratamento de erros

Diferente do SDK de Node, **este SDK levanta exceções**. Ele não retorna `{ data, error, success }`. Toda falha vira uma exceção tipada que herda de `AbacatePay::Error`, então você pode capturar tudo de uma vez ou tratar caso a caso.

</div>

```ruby
begin
  checkout = AbacatePay.checkouts.create(data)
rescue AbacatePay::ConfigurationError => e
  # token ausente ou vazio
rescue AbacatePay::ApiError => e
  # a API recusou a chamada, ou houve falha de rede/timeout
  Rails.logger.error(e.message)
end
```

<div align="center">

| Exceção | Quando acontece |
|---|---|
| `AbacatePay::ConfigurationError` | Token ausente ou vazio |
| `AbacatePay::ApiError` | Erro da API, falha de rede ou timeout |
| `AbacatePay::Webhooks::SignatureError` | Assinatura de webhook ausente, vazia ou inválida |
| `AbacatePay::Webhooks::PayloadError` | Corpo do webhook malformado ou que não é um objeto JSON |

Erros de rede e timeout são normalizados para `ApiError`, com a mensagem da API preservada quando ela envia uma.

## Webhooks

Endpoints de webhook são públicos. A AbacatePay usa **dois mecanismos**, e a documentação orienta usar os dois: o `webhookSecret` na query autentica a origem, e a assinatura HMAC garante que o corpo não foi alterado. A chave HMAC é pública e global: ela sozinha não prova origem.

</div>

```ruby
payload   = request.body.read
signature = request.headers['X-Webhook-Signature']

begin
  # 1. Autentica a origem com o secret que você definiu ao criar o webhook,
  #    enviado pela AbacatePay como query parameter.
  AbacatePay::Webhooks.verify_secret!(
    received: params[:webhookSecret],
    expected: ENV['ABACATEPAY_WEBHOOK_SECRET']
  )

  # 2. Verifica a integridade do corpo. A chave HMAC é pública, então este
  #    passo sozinho não prova origem. Por isso os dois juntos.
  event = AbacatePay::Webhooks.construct_event(
    payload: payload, signature: signature
  )
rescue AbacatePay::Webhooks::SignatureError
  return head :unauthorized
rescue AbacatePay::Webhooks::PayloadError
  return head :bad_request
end

case event.type
when 'checkout.completed'    then handle_payment(event.data)
when 'checkout.refunded'     then handle_refund(event.data)
when 'subscription.renewed'  then handle_renewal(event.data)
end
```

<div align="center">

Header ausente, secret vazio, assinatura forjada e corpo malformado são todos tratados como casos esperados: levantam erro tipado em vez de derrubar o endpoint. A comparação de assinatura é feita em tempo constante.

Os métodos de baixo nível continuam disponíveis:

</div>

```ruby
# Levanta SignatureError se a assinatura estiver ausente ou inválida
AbacatePay::Webhooks.verify!(payload: payload, signature: signature, secret: secret)

# Contraparte booleana. Nunca levanta exceção
AbacatePay::Webhooks.valid?(payload: payload, signature: signature, secret: secret)

# Faz parse de um corpo já verificado
AbacatePay::Webhooks.parse(payload)
```

<div align="center">

### Eventos disponíveis

| Categoria | Eventos |
|---|---|
| Checkout | `checkout.completed`, `checkout.refunded`, `checkout.disputed` |
| Transparent | `transparent.completed`, `transparent.refunded`, `transparent.disputed` |
| Subscription | `subscription.completed`, `subscription.renewed`, `subscription.cancelled`, `subscription.payment_failed`, `subscription.trial_started` |
| Transfer | `transfer.completed`, `transfer.failed` |
| Payout | `payout.completed`, `payout.failed` |

## Recursos

Todos os recursos são acessíveis pela fachada `AbacatePay.<recurso>`.

| Recurso | Métodos |
|---|---|
| `customers` | `list` `get` `create` `delete` |
| `products` | `list` `get` `create` `delete` |
| `coupons` | `list` `get` `create` `delete` `toggle` |
| `checkouts` | `list` `get` `create` `refund` |
| `subscriptions` | `list` `create` `cancel` `change_plan` `record_usage` |
| `transparents` | `list` `create` `check` `simulate_payment` `refund` |
| `pix` | `list` `get` `send_pix` |
| `payouts` | `list` `get` `create` |
| `store` | `get` `merchant_info` `mrr` `revenue` |
| `payment_links` | `list` `get` `create` `refund` |
| `webhook_endpoints` | `list` `get` `create` `delete` |

### Clientes

</div>

```ruby
AbacatePay.customers.list
AbacatePay.customers.get('cust_123')
AbacatePay.customers.delete('cust_123')

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
```

<div align="center">

### Produtos

</div>

```ruby
AbacatePay.products.create(
  AbacatePay::Resources::Products.new(
    external_id: 'my-product-1',
    name: 'Monthly Plan',
    price: 2990,        # R$ 29,90 em centavos
    currency: 'BRL',
    description: 'Acesso a todos os recursos',
    cycle: 'MONTHLY'    # ou nil para pagamento único
  )
)
```

<div align="center">

### Cupons

</div>

```ruby
AbacatePay.coupons.create(
  AbacatePay::Resources::Coupons.new(
    code: 'SAVE20',
    discount: 20,
    discount_kind: 'PERCENTAGE', # ou 'FIXED'
    max_redeems: 100
  )
)

AbacatePay.coupons.toggle('coup_123')
```

<div align="center">

### Assinaturas

Exigem exatamente um produto com `cycle` definido.

</div>

```ruby
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

<div align="center">

### PIX transparente (QR Code)

</div>

```ruby
AbacatePay.transparents.create(
  AbacatePay::Resources::Transparents.new(
    amount: 1000,
    description: 'Pedido #123',
    expires_in: 3600
  )
)

AbacatePay.transparents.check('tr_123')
AbacatePay.transparents.simulate_payment('tr_123') # apenas em dev mode
```

<div align="center">

### Transferências PIX

</div>

```ruby
AbacatePay.pix.send_pix(
  AbacatePay::Resources::PixTransfers.new(
    amount: 500,
    external_id: 'transfer-001',
    description: 'Pagamento ao fornecedor',
    key: '12345678900',
    key_type: 'CPF' # CPF, CNPJ, PHONE, EMAIL, RANDOM, BR_CODE
  )
)
```

<div align="center">

### Saques

Valor mínimo de R$ 3,50.

</div>

```ruby
AbacatePay.payouts.create(
  AbacatePay::Resources::Payouts.new(
    amount: 5000,
    external_id: 'withdrawal-001',
    description: 'Saque mensal'
  )
)
```

<div align="center">

### Boleto

Boleto tem vencimento, juros e multa próprios. Todos os valores em centavos.

</div>

```ruby
AbacatePay.checkouts.create(
  AbacatePay::Resources::Checkouts.new(
    methods: ['BOLETO'],
    due_date: '2026-08-15',              # opcional; default 3 dias úteis
    interest: { value: 100 },            # juros ao mês
    fine: { value: 200, type: 'PERCENTAGE' }, # ou type: 'FIXED'
    products: [
      AbacatePay::Resources::Billings::Product.new(external_id: 'prod_123', quantity: 1)
    ]
  )
)
```

<div align="center">

No checkout transparente, o boleto exige nome e CPF/CNPJ do pagador, o SDK valida antes de chamar a API:

</div>

```ruby
charge = AbacatePay::Resources::Transparents.new(amount: 25_000, due_date: '2026-08-15')
# charge.customer precisa ter metadata.name e metadata.tax_id

boleto = AbacatePay.transparents.create(charge, method: 'BOLETO')
boleto.bar_code        # linha digitável
boleto.url             # PDF para impressão
boleto.br_code         # PIX alternativo da mesma cobrança
```

<div align="center">

### Parcelamento e order bump

</div>

```ruby
AbacatePay.checkouts.create(
  AbacatePay::Resources::Checkouts.new(
    methods: ['CARD'],
    max_installments: 12,
    up_sell_product_id: 'prod_bump',
    custom_metadata: { origem: 'app-mobile' },
    products: [
      AbacatePay::Resources::Billings::Product.new(external_id: 'prod_123', quantity: 1)
    ]
  )
)
```

<div align="center">

### Links de pagamento

Um link reutilizável, pago por vários clientes de forma independente, vendas em massa, rifas, formulários de inscrição. Para uma cobrança por cliente, use `checkouts`.

</div>

```ruby
link = AbacatePay.payment_links.create(
  AbacatePay::Resources::Checkouts.new(
    methods: ['PIX', 'CARD'],
    external_id: 'campanha-black-friday',
    products: [
      AbacatePay::Resources::Billings::Product.new(external_id: 'prod_123', quantity: 1)
    ]
  )
)

puts link.url # compartilhe esta URL
```

<div align="center">

### Estornos

O estorno é sempre integral, a AbacatePay não faz estorno parcial.

</div>

```ruby
AbacatePay.checkouts.refund('bill_abc123xyz')
AbacatePay.transparents.refund('pix_char_abc123xyz')
AbacatePay.payment_links.refund('char_abc123xyz')
```

<div align="center">

### Cancelar assinatura

Cancela imediatamente; parcelas futuras pendentes são canceladas junto.

</div>

```ruby
AbacatePay.subscriptions.cancel('subs_abc123xyz')

# Upgrade/downgrade, vale a partir do próximo ciclo
AbacatePay.subscriptions.change_plan('subs_abc123xyz', product_id: 'prod_pro', quantity: 1)

# Cobrança por uso, produto sem ciclo
AbacatePay.subscriptions.record_usage('subs_abc123xyz', product_id: 'prod_api', units: 50)
```

<div align="center">

### Registro de webhooks

Isto gerencia **para onde** a AbacatePay entrega os eventos. Para verificar uma entrega recebida, use `Webhooks.construct_event`.

</div>

```ruby
AbacatePay.webhook_endpoints.create(
  name:     'Pagamentos',
  endpoint: 'https://meusite.com/webhooks/abacatepay', # precisa ser HTTPS
  secret:   ENV['ABACATEPAY_WEBHOOK_SECRET'],
  events:   ['checkout.completed', 'subscription.renewed']
)

AbacatePay.webhook_endpoints.list
AbacatePay.webhook_endpoints.delete('wh_123')
```

<div align="center">

### Loja

</div>

```ruby
store = AbacatePay.store.get
store.balance.available # => 10000
store.balance.pending   # => 500
store.balance.blocked   # => 0

AbacatePay.store.revenue(start_date: '2026-01-01', end_date: '2026-03-30')
```

<div align="center">

## Enums

Os valores são validados na construção do recurso, um valor inválido levanta `ArgumentError` antes de qualquer chamada de rede.

| Enum | Valores |
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

## Contribuindo

</div>

```bash
git clone https://github.com/AbacatePay/abacatepay-ruby-sdk.git
cd abacatepay-ruby-sdk
bundle install
bundle exec rake        # specs + rubocop
```

<div align="center">

Antes de abrir um PR, garanta que `bundle exec rake` passa e que a cobertura não caiu, o CI roda os specs em Ruby 3.2, 3.3, 3.4 e 4.0, mais RuboCop, auditoria de dependências e build do gem.

## Licença

MIT

Feito com 🥑 pela equipe AbacatePay</br>
Open source, de verdade.

</div>
