class DashboardsController < ApplicationController
  def show
    # Most recently worked-on first (ticking a step touches its path).
    # Steps are preloaded so each card can find its next step and time left
    # without a query per path; step counts come from counter caches.
    @learning_paths = Current.user.learning_paths
      .includes(:learning_goal, :path_steps)
      .order(updated_at: :desc)
      .load
    @learning_stats = LearningStats.new(Current.user)
  end
end
