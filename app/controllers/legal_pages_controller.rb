# Privacy, terms, refunds and contact: public pages every visitor (and every
# payment-provider reviewer) can reach from any footer.
class LegalPagesController < ApplicationController
  allow_unauthenticated_access
  layout "legal"

  def privacy; end
  def terms; end
  def refunds; end
  def contact; end
end
