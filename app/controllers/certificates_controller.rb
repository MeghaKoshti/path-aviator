# The public completion certificate behind /c/:token. Anyone with the link can
# see it; the owner also sees the LinkedIn and revoke controls.
class CertificatesController < ApplicationController
  allow_unauthenticated_access
  layout "marketing"

  def show
    @learning_path = LearningPath.includes(:user, :path_steps).find_by!(certificate_token: params[:token])
    # It says "completed every step", so it's offline while a step is un-ticked or the path is re-planned.
    raise ActiveRecord::RecordNotFound unless @learning_path.completed?

    @owner_viewing = authenticated? && Current.user == @learning_path.user
    response.headers["X-Robots-Tag"] = "noindex"
  end
end
