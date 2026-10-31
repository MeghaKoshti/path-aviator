# Confirms an email address from the emailed link, and resends that link.
class EmailVerificationsController < ApplicationController
  # The link may be opened on another device, where nobody is signed in.
  allow_unauthenticated_access only: :show
  rate_limit to: 3, within: 15.minutes, only: :create, by: -> { Current.user.id },
    with: -> { redirect_back_or_to dashboard_path, alert: "We’ve just sent a few links. Check your inbox, or try again in 15 minutes." }

  def show
    user = User.find_by_token_for(:email_verification, params[:token])

    if user
      user.verify_email!
      redirect_to (authenticated? ? dashboard_path : new_session_path), notice: "Thanks, your email is confirmed."
    else
      redirect_to (authenticated? ? dashboard_path : new_session_path),
        alert: "That confirmation link is invalid or has expired. Sign in and ask for a new one."
    end
  end

  # "Resend the link"
  def create
    if Current.user.email_verified?
      redirect_back_or_to dashboard_path, notice: "Your email is already confirmed."
    else
      Current.user.send_email_verification
      redirect_back_or_to dashboard_path, notice: "We sent a new link to #{Current.user.email_address}."
    end
  end
end
