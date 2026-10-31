module BillingHelper
  # Where "Upgrade to Pro" goes: the pricing page once it exists, otherwise
  # the plan section of settings.
  def upgrade_path
    respond_to?(:pricing_path) ? pricing_path : settings_path(anchor: "plan")
  end

  # "2 of 3 free paths left this month"
  def generations_left_label(quota)
    noun = quota.plan.free? ? "free #{"path".pluralize(quota.limit)}" : "path".pluralize(quota.limit)
    "#{quota.remaining} of #{quota.limit} #{noun} left this month"
  end
end
