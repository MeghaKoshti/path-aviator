# "Copy this path": a signed-in visitor gets their own copy of a shared path,
# with fresh progress. Guests are sent to sign-up, which makes the copy after.
class SharedPaths::CopiesController < ApplicationController
  rate_limit to: 10, within: 10.minutes, by: -> { Current.user&.id || request.remote_ip },
    with: -> { redirect_to shared_path_path(params[:token]), alert: "That’s a lot of copies. Try again in a few minutes." }

  def create
    source = LearningPath.ready.find_by!(share_token: params[:token])
    copy = source.copy_for(Current.user)
    redirect_to copy, notice: "Path copied. It’s yours now: tick steps off as you go.", status: :see_other
  end

  private
    # A guest who clicks Copy comes back to the shared page after signing in.
    def request_authentication
      session[:return_to_after_authenticating] = shared_path_url(params[:token])
      redirect_to new_session_path, status: :see_other
    end
end
