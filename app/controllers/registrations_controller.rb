class RegistrationsController < ApplicationController
  layout "auth"
  allow_unauthenticated_access
  before_action :redirect_signed_in_user
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_registration_url, alert: "Too many sign-up attempts. Try again in a few minutes." }

  def new
    @user = User.new
    # Someone who already has an account picks "Sign in" here instead; bring
    # them back to the plan they wanted to copy.
    if (plan_url = plan_to_copy_url)
      session[:return_to_after_authenticating] = plan_url
    end
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      Event.track(:signed_up, user: @user)
      @user.send_email_verification
      start_new_session_for @user
      if (shared = path_to_copy)
        redirect_to shared.copy_for(@user), notice: "Welcome aboard! The plan is copied to your account."
      else
        redirect_to new_learning_goal_path, notice: "Welcome aboard! Let’s plan your first path."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def registration_params
      params.expect(user: [ :name, :email_address, :password, :password_confirmation, :time_zone ])
    end

    # Set when a guest clicked "Copy this path" on a shared page (copy=token)
    # or "Make this mine" on a /learn study plan (learn=slug).
    def path_to_copy
      if params[:copy].present?
        LearningPath.ready.find_by(share_token: params[:copy])
      elsif params[:learn].present?
        LearnTopic.all.find { |topic| topic.slug == params[:learn] }
      end
    end

    def plan_to_copy_url
      if params[:copy].present?
        shared_path_url(params[:copy])
      elsif params[:learn].present?
        learn_topic_url(params[:learn])
      end
    end

    def redirect_signed_in_user
      redirect_to dashboard_path if authenticated?
    end
end
