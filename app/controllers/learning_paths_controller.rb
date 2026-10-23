class LearningPathsController < ApplicationController
  before_action :set_learning_path

  def show
    respond_to do |format|
      format.html
      # Polled by the path page while generating (path_status_controller.js).
      format.json { render json: { status: @learning_path.status } }
    end
  end

  # "Try again" on a failed path and "Regenerate" on a ready one. Steps and
  # progress are thrown away and the generation job runs again.
  def regenerate
    @learning_path.regenerate! unless @learning_path.generating?
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
