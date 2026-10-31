# Which currency and billing interval to show prices in.
# An explicit choice (the ?currency param or the toggle's cookie) wins. Otherwise
# visitors whose browser asks for an Indian locale see rupees, everyone else
# dollars; pricing_controller.js also switches to rupees for an Indian time zone.
module PricingPreferences
  extend ActiveSupport::Concern

  included do
    helper_method :pricing_currency, :pricing_interval, :pricing_currency_chosen?
  end

  private
    def pricing_currency
      chosen_pricing_currency || (india_visitor? ? :inr : :usd)
    end

    def pricing_interval
      Plan::INTERVALS.find { |interval| interval.to_s == params[:interval] } || :month
    end

    def pricing_currency_chosen?
      chosen_pricing_currency.present?
    end

    def chosen_pricing_currency
      choice = params[:currency].presence || cookies[:currency]
      Plan::CURRENCIES.find { |currency| currency.to_s == choice }
    end

    # en-IN, hi-IN, ta-IN… or plain Hindi.
    def india_visitor?
      request.headers["Accept-Language"].to_s.match?(/(?:\A|[\s,])(?:[a-z]{2,3}-IN|hi)(?:[;,]|\z)/i)
    end
end
