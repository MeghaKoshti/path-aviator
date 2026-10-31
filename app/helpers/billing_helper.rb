module BillingHelper
  # Where "Upgrade to Pro" goes: the pricing page, which posts to checkout.
  def upgrade_path
    pricing_path
  end

  # "2 of 3 free paths left this month"
  def generations_left_label(quota)
    noun = quota.plan.free? ? "free #{"path".pluralize(quota.limit)}" : "path".pluralize(quota.limit)
    "#{quota.remaining} of #{quota.limit} #{noun} left this month"
  end

  # Prices and price formatting come from PricingHelper. This is the currency
  # settings shows: a ?currency= toggle, the pricing page's choice (cookie),
  # else a guess from the request.
  def billing_currency
    params[:currency].presence_in(Billing::CURRENCIES) || cookies[:currency].presence_in(Billing::CURRENCIES) ||
      Billing.currency_for(request)
  end

  # Indian prices include GST (the merchant of record adds the tax line).
  def price_tax_note(currency)
    "incl. GST" if currency.to_s == "inr"
  end
end
