# Prices come from Plan (config/plans.yml) in paise/cents; these helpers only format them.
module PricingHelper
  CURRENCY_UNITS = { inr: "₹", usd: "$" }.freeze
  CURRENCY_LABELS = { inr: "₹ INR", usd: "$ USD" }.freeze

  # 19900, :inr → "₹199"; 149900, :inr → "₹1,499"; 650, :usd → "$6.50"
  def format_price(cents, currency)
    number_to_currency(cents / 100.0, unit: CURRENCY_UNITS.fetch(currency.to_sym), format: "%u%n",
      precision: (cents % 100).zero? ? 0 : 2)
  end

  def plan_price(plan, currency:, interval:)
    format_price(plan.price_cents(currency:, interval:), currency)
  end

  # The yearly price spread over 12 months, to the nearest whole rupee or dollar.
  def yearly_price_per_month(plan, currency:)
    format_price((plan.price_cents(currency:, interval: :year) / 12.0).round(-2).to_i, currency)
  end

  # How much yearly saves against 12 monthly payments, rounded down so we never overstate it.
  def yearly_savings_percent(plan, currency:)
    monthly_total = plan.price_cents(currency:, interval: :month) * 12
    (100 - plan.price_cents(currency:, interval: :year) * 100.0 / monthly_total).floor
  end

  # One price variant (currency and/or interval). pricing_controller.js shows the
  # one matching the toggles; the server shows the right one before JS runs.
  def pricing_variant(currency: nil, interval: nil, tag_name: :span, **options, &block)
    hidden = (currency && currency != pricing_currency) || (interval && interval != pricing_interval)
    content_tag(tag_name, **options, hidden: hidden, data: { pricing_target: "variant", currency:, interval: }, &block)
  end

  # Free vs Pro comparison rows: [label, free cell, pro cell]. A cell is true,
  # false or a short note. Driven by the plan catalog so the table can't drift.
  def plan_comparison_rows(free, pro)
    cell = ->(plan, feature, note = nil) { plan.includes?(feature) ? (note || true) : false }
    [
      [ "New learning paths each month", free.monthly_generations.to_s, pro.includes?(:unlimited_paths) ? "Unlimited (fair use)" : pro.monthly_generations.to_s ],
      [ "Progress, notes, weekly stats and streak", cell.(free, :progress_tracking), cell.(pro, :progress_tracking) ],
      [ "Links checked when your path is planned", cell.(free, :link_checking), cell.(pro, :link_checking) ],
      [ "Weekly re-check, with broken links replaced", cell.(free, :weekly_link_recheck), cell.(pro, :weekly_link_recheck) ],
      [ "Public progress page for your CV", cell.(free, :share_link, "With a “Made with Path Aviator” line"),
        cell.(pro, :share_link, pro.includes?(:no_share_branding) ? "Without branding" : nil) ],
      [ "Plan from a job post", cell.(free, :job_post_paths), cell.(pro, :job_post_paths) ],
      [ "Completion certificate with LinkedIn “Add to profile”", cell.(free, :certificates), cell.(pro, :certificates) ],
      [ "Download all your data", cell.(free, :data_export), cell.(pro, :data_export) ]
    ]
  end

  def pricing_faqs
    free_paths = pluralize(Plan.free.monthly_generations, "new path")
    [
      [ "How is this different from asking ChatGPT for a study plan?",
        safe_join([
          tag.p("A chat gives you a list once. Path Aviator keeps the plan going with you:"),
          tag.ul(class: "mt-3 list-disc space-y-2 pl-5") do
            safe_join([
              tag.li("Every link is checked when your path is planned, so you don’t hit dead pages or made-up URLs. Pro re-checks them weekly and swaps out broken ones."),
              tag.li("The plan is paced to the hours you actually have each week, with a time estimate on every step."),
              tag.li("Ticking steps builds your weekly stats and streak, so you can see when you’re slipping, not just when you start."),
              tag.li("Your public progress page and certificate show interviewers what you’ve done, not just what you planned.")
            ])
          end
        ]) ],
      [ "Can I cancel any time?",
        safe_join([ "Yes, from Settings. You keep Pro until the end of the period you paid for, then move to Free. Your paths, progress and notes stay. See the ",
                    link_to("Refund & Cancellation Policy", refunds_path, class: "font-medium text-brand-700 underline underline-offset-4"), "." ]) ],
      [ "Can I get a refund?",
        "Yes. Ask within 7 days of your first payment and we refund it in full. Duplicate charges or charges after you cancelled are always refunded." ],
      [ "What counts as a new path on Free?",
        "Planning a path, or re-planning one, uses one of your #{free_paths} a month. Ticking steps, notes, sharing and copying someone else’s shared path are unlimited." ],
      [ "How do I pay?",
        "UPI and Indian cards in rupees, or international cards in dollars. Checkout is run by Dodo Payments, our merchant of record, which also sends your invoice and handles GST or VAT. We never see your card or bank details." ],
      [ "Why are rupee prices lower?",
        "Prices are set for what learning tools cost in each market, so developers in India pay a rupee price instead of a converted dollar one." ],
      [ "What happens to my data?",
        safe_join([ "It’s used to run your account, never sold, and never used to train AI models. You can download it or delete your account any time. Details are in the ",
                    link_to("Privacy Policy", privacy_path, class: "font-medium text-brand-700 underline underline-offset-4"), "." ]) ]
    ]
  end

  # The checkout route arrives with billing; until then "Upgrade" goes to sign-up.
  def pro_checkout_available?
    respond_to?(:billing_checkout_path)
  end

  def pro_user?(user)
    ProAccess.granted?(user)
  end
end
