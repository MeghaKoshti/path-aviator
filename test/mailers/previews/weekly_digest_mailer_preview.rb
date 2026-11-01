# Preview at http://localhost:3000/rails/mailers/weekly_digest_mailer
class WeeklyDigestMailerPreview < ActionMailer::Preview
  def check_in
    WeeklyDigestMailer.check_in(User.find_by(email_address: DemoAccount.email) || User.first)
  end
end
