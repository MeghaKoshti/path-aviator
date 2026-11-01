class LearningPathsController < ApplicationController
  include GenerationGuard

  before_action :set_learning_path
  rate_limit to: 5, within: 10.minutes, only: :regenerate, by: -> { Current.user.id },
    with: -> { redirect_to learning_path_path(params[:id]), alert: GenerationGuard::RATE_LIMIT_MESSAGE, status: :see_other }

  def show
    respond_to do |format|
      format.html
      # Polled by the path page while generating (path_status_controller.js).
      format.json { render json: { status: @learning_path.status } }
    end
  end

  # "Try again" on a failed path and "Regenerate" on a ready one. Steps and
  # progress are thrown away and the generation job runs again. It counts
  # against the monthly quota like a new path does.
  def regenerate
    unless @learning_path.generating?
      if (reason = generation_refusal)
        return redirect_to @learning_path, alert: generation_quota.refusal_message(reason), status: :see_other
      end

      record_generation(@learning_path)
      @learning_path.regenerate!
    end
    redirect_to @learning_path, status: :see_other
  end

  # A path only exists for its goal, so the goal goes too.
  def destroy
    @learning_path.learning_goal.destroy!
    notice = "Deleted “#{@learning_path.title.presence || @learning_path.learning_goal.topic}”."

    respond_to do |format|
      format.turbo_stream do
        if params[:from] == "dashboard"
          @learning_paths = Current.user.learning_paths
          @learning_stats = LearningStats.new(Current.user)
          flash.now[:notice] = notice
        else
          redirect_to dashboard_path, notice: notice, status: :see_other
        end
      end
      format.html { redirect_to dashboard_path, notice: notice, status: :see_other }
    end
  end

  private
    # Scoped to the signed-in user, so anyone else's path is a 404.
    def set_learning_path
      @learning_path = Current.user.learning_paths.find(params[:id])
    end
end
