class LearningPathsController < ApplicationController
  before_action :set_learning_path

  def show
  end

  private
    # Scoped to the signed-in user, so anyone else's path is a 404.
    def set_learning_path
      @learning_path = Current.user.learning_paths.find(params[:id])
    end
end
