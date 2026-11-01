class PricingController < ApplicationController
  include PricingPreferences
  allow_unauthenticated_access
  layout "marketing"

  def show
    @free = Plan.free
    @pro = Plan.pro
  end
end
