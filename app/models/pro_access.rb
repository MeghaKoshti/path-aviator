# One place that answers "does this person have Pro?". Billing adds User#pro?;
# until it does, nobody is Pro and Pro-only features stay locked.
module ProAccess
  def self.granted?(user)
    user.respond_to?(:pro?) && user.pro? ? true : false
  end
end
