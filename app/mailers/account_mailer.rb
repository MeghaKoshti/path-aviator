# Emails about the account itself (not learning reminders).
class AccountMailer < ApplicationMailer
  def verify_email(user)
    @user = user
    @url = verify_email_url(user.generate_token_for(:email_verification))
    @expires_in = User::EMAIL_VERIFICATION_EXPIRY.inspect # "3 days"

    mail to: user.email_address, subject: "Confirm your email for Path Aviator"
  end
end
