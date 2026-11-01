# Preview all emails at http://localhost:3000/rails/mailers/account_mailer
class AccountMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/account_mailer/verify_email
  def verify_email
    AccountMailer.verify_email(User.take)
  end
end
