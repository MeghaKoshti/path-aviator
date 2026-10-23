# The public page behind a share link. Anyone with the link can see it,
# signed in or not. It shows the plan and progress only: never notes, the
# goal description or the owner's email.
class SharedPathsController < ApplicationController
  allow_unauthenticated_access
  layout "marketing"

  def show
    # A path that is being re-planned has no steps to show, so it 404s until it's ready.
    @learning_path = LearningPath.ready.includes(:user, :path_steps).find_by!(share_token: params[:token])
    response.headers["X-Robots-Tag"] = "noindex"
  end
end
