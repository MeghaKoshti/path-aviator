# The weekly email's unsubscribe link: one click, no sign-in. The token is
# signed (User.generates_token_for :unsubscribe), so it only works for the
# account it was made for.
class UnsubscribesController < ApplicationController
  allow_unauthenticated_access
  # Mail clients' one-click unsubscribe (RFC 8058) posts without a CSRF token.
  skip_forgery_protection only: :create
  before_action :set_user
  layout "auth"

  # Following the link in the email unsubscribes straight away.
  def show
    @user.update!(weekly_digest: false)
  end

  def create
    @user.update!(weekly_digest: false)
    head :ok
  end

  # "Changed your mind?" on the confirmation page.
  def destroy
    @user.update!(weekly_digest: true)
    redirect_to unsubscribe_path(params[:token]), notice: "You’re subscribed again. See you on Sunday.", status: :see_other
  end

  private
    def set_user
      @user = User.find_by_token_for(:unsubscribe, params[:token]) or render :invalid, status: :not_found
    end
end
