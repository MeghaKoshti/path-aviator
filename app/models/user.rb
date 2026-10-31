class User < ApplicationRecord
  # Old names some browsers still report, for servers whose tz database
  # doesn't carry the "backward" links.
  TIME_ZONE_ALIASES = {
    "Asia/Calcutta" => "Asia/Kolkata", "Asia/Katmandu" => "Asia/Kathmandu", "Asia/Saigon" => "Asia/Ho_Chi_Minh",
    "Asia/Rangoon" => "Asia/Yangon", "Europe/Kiev" => "Europe/Kyiv", "America/Buenos_Aires" => "America/Argentina/Buenos_Aires"
  }.freeze

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :generations, dependent: :delete_all
  # Paths are declared first so they are destroyed before the goals they point to.
  has_many :learning_paths, dependent: :destroy
  has_many :learning_goals, dependent: :destroy
  has_many :data_exports, dependent: :destroy
  # Analytics rows outlive the account, but no longer point at anyone.
  has_many :events, dependent: :nullify

  # The plan the user has right now. Billing keeps it in step with the
  # subscription, so checks like pro? never need to look at payments.
  enum :plan, { free: "free", pro: "pro" }, default: "free", validate: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(name) { name.strip.presence }
  # Stored as an IANA name ("Asia/Kolkata"). Anything unknown becomes UTC
  # rather than an error: it usually comes from the browser, not the person.
  normalizes :time_zone, with: ->(zone) {
    zone = zone.to_s.strip
    name = ActiveSupport::TimeZone[TIME_ZONE_ALIASES.fetch(zone, zone)]&.tzinfo&.name
    name.nil? || name == "Etc/UTC" ? "UTC" : name
  }

  # The weekly email's unsubscribe link. It needs no sign-in and never expires.
  generates_token_for :unsubscribe

  validates :email_address, presence: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP },
                            uniqueness: { case_sensitive: false }
  # allow_nil lets users update their profile without re-entering a password;
  # has_secure_password already requires one on create.
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :name, length: { maximum: 100 }, allow_nil: true

  # People listed in ADMIN_EMAILS (comma-separated) can open /admin.
  def admin?
    admins = ENV.fetch("ADMIN_EMAILS", "").split(",").map { |email| email.strip.downcase }
    !demo? && admins.include?(email_address)
  end

  # "Today", "this week" and streaks follow this zone.
  def zone
    ActiveSupport::TimeZone[time_zone] || ActiveSupport::TimeZone["UTC"]
  end

  # A user without a goal still needs to go through onboarding.
  def onboarded?
    learning_goals.exists?
  end

  # The Plan catalog entry (limits, prices, features) for the user's plan.
  def current_plan
    Plan.find(plan)
  end

  def generation_quota
    GenerationQuota.new(self)
  end

  def generations_left_this_month
    generation_quota.remaining
  end

  # The shared demo account everyone signs in to. Its sign-in details and the
  # account itself are locked; the learning features work as for anyone.
  def demo?
    email_address.to_s.casecmp?(DemoAccount.email)
  end

  # Pro feature (see ProAccess).
  def weekly_link_recheck?
    ProAccess.granted?(self)
  end

  # Everyone gets one path planned from a job post; after that it's Pro.
  def can_plan_from_job_post?
    ProAccess.granted?(self) || !learning_goals.where.not(job_post: nil).exists?
  end
end
