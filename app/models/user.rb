class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  # Paths are declared first so they are destroyed before the goals they point to.
  has_many :learning_paths, dependent: :destroy
  has_many :learning_goals, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(name) { name.strip.presence }

  validates :email_address, presence: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP },
                            uniqueness: { case_sensitive: false }
  # allow_nil lets users update their profile without re-entering a password;
  # has_secure_password already requires one on create.
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :name, length: { maximum: 100 }, allow_nil: true

  # A user without a goal still needs to go through onboarding.
  def onboarded?
    learning_goals.exists?
  end

  # The shared demo account everyone signs in to. Its sign-in details and the
  # account itself are locked; the learning features work as for anyone.
  def demo?
    email_address.to_s.casecmp?(DemoAccount.email)
  end

  # Pro feature. `pro?` arrives with billing; until then nobody has it.
  def weekly_link_recheck?
    respond_to?(:pro?) && pro?
  end

  # Everyone gets one path planned from a job post; after that it's Pro.
  def can_plan_from_job_post?
    (respond_to?(:pro?) && pro?) || !learning_goals.where.not(job_post: nil).exists?
  end
end
