# Public, indexable study plans (/learn and /learn/:slug) for search visitors.
class LearnTopicsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  layout "marketing", only: %i[ index show ]
  rate_limit to: 10, within: 10.minutes, only: :copy,
    with: -> { redirect_to learn_topic_path(params[:id]), alert: "That’s a lot of copies. Try again in a few minutes." }

  def index
    @topics = LearnTopic.all
  end

  def show
    @topic = LearnTopic.find(params[:id])
  end

  # "Make this mine" for a signed-in visitor. Guests go through sign-up instead.
  def copy
    path = LearnTopic.find(params[:id]).copy_for(Current.user)
    redirect_to path, notice: "The plan is yours. Tick steps off as you go.", status: :see_other
  end

  private
    def request_authentication
      session[:return_to_after_authenticating] = learn_topic_url(params[:id])
      redirect_to new_session_path, status: :see_other
    end
end
