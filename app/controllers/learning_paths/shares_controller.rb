# Owner switches for a path's public link: create (or replace) it, or turn it off.
class LearningPaths::SharesController < ApplicationController
  before_action :set_learning_path

  def create
    notice = @learning_path.shared? ? "New link created. The old link no longer works." : "Share link created. Anyone with the link can view this path."
    @learning_path.share!
    redirect_to learning_path_path(@learning_path, anchor: "share"), notice: notice, status: :see_other
  end

  def destroy
    @learning_path.unshare!
    redirect_to learning_path_path(@learning_path, anchor: "share"), notice: "Sharing is off. The link no longer works.", status: :see_other
  end

  private
    # Scoped to the signed-in user, so anyone else's path is a 404.
    def set_learning_path
      @learning_path = Current.user.learning_paths.find(params[:learning_path_id])
    end
end
