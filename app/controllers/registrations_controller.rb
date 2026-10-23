class RegistrationsController < ApplicationController
  layout "auth"
  allow_unauthenticated_access
  before_action :redirect_signed_in_user
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_registration_url, alert: "Too many sign-up attempts. Try again in a few minutes." }

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      start_new_session_for @user
      redirect_to new_learning_goal_path, notice: "Welcome aboard! Let’s plan your first path."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def registration_params
      params.expect(user: [ :name, :email_address, :password, :password_confirmation ])
    end

    def redirect_signed_in_user
      redirect_to dashboard_path if authenticated?
    end
end
