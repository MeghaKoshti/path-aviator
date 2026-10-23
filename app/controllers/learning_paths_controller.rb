class LearningPathsController < ApplicationController
  before_action :set_learning_path

  def show
  end

  # "Try again" on a failed path. Steps and progress are thrown away and the
  # generation job runs again.
  def regenerate
    @learning_path.regenerate! unless @learning_path.generating?
    redirect_to @learning_path, status: :see_other
  end

  private
    # Scoped to the signed-in user, so anyone else's path is a 404.
    def set_learning_path
      @learning_path = Current.user.learning_paths.find(params[:id])
    end
end
