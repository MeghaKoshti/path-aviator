# Where the provider sends people after paying. The webhook that makes them
# Pro may arrive a moment later, so the page waits for it.
class Billing::ReturnsController < ApplicationController
  def show
    @pro = Current.user.pro?
  end
end
