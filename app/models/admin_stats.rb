# The numbers on /admin. Columns that arrive with billing (users.plan,
# users.email_verified_at) are counted only once they exist.
class AdminStats
  FUNNEL = %w[signed_up path_ready first_step_done returned_week_2 upgraded].freeze
  # A blended Gemini Flash price for prompt and answer tokens together; the
  # cost shown is an estimate, so it only needs to be the right size.
  DEFAULT_USD_PER_MILLION_TOKENS = 1.5

  def initialize(now: Time.current)
    @now = now
  end

  def users = User.count
  def new_users_this_week = User.where(created_at: (@now - 7.days)..).count

  def verified_users
    User.where.not(email_verified_at: nil).count if User.column_names.include?("email_verified_at")
  end

  def pro_users
    User.where(plan: "pro").count if User.column_names.include?("plan")
  end

  # { "ready" => 12, "generating" => 1, "failed" => 2 }, every status listed.
  def paths_by_status
    counts = LearningPath.group(:status).count
    LearningPath.statuses.keys.index_with { |status| counts.fetch(status, 0) }
  end

  def generations_today = generations.since(@now.beginning_of_day).count
  def generations_this_month = generations.since(@now.beginning_of_month).count

  def estimated_tokens_this_month
    Event.named(:path_ready).since(@now.beginning_of_month).pluck(:properties).sum { |properties| properties["estimated_tokens"].to_i }
  end

  def estimated_cost_this_month_usd
    rate = ENV.fetch("AI_USD_PER_MILLION_TOKENS", DEFAULT_USD_PER_MILLION_TOKENS).to_f
    (estimated_tokens_this_month * rate / 1_000_000).round(2)
  end

  # People who reached each milestone in the last 30 days.
  def funnel
    counts = Event.since(@now - 30.days).where(name: FUNNEL).group(:name).distinct.count(:user_id)
    FUNNEL.index_with { |name| counts.fetch(name, 0) }
  end

  def recent_failures
    Event.named(:path_failed).includes(:user).order(created_at: :desc).limit(50)
  end

  private
    def generations
      Event.where(name: %w[path_ready path_failed])
    end
end
