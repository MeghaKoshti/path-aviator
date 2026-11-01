# One place that answers "does this person have Pro?" for Pro-only features
# (job-post paths, weekly link re-checks, certificates). Billing keeps
# users.plan in step with the subscription (User#pro?).
module ProAccess
  def self.granted?(user)
    user.present? && user.pro?
  end
end
