class Settings::ProfilesController < SettingsController
  def update
    @profile = User.find(Current.user.id)
    @profile.assign_attributes(params.expect(user: [ :name, :email_address ]))

    if email_change_missing_password?
      @profile.validate
      @profile.errors.add(:password_challenge, "is needed to change your email")
      render_settings status: :unprocessable_entity
    elsif @profile.save
      redirect_to settings_path, notice: "Profile saved.", status: :see_other
    else
      render_settings status: :unprocessable_entity
    end
  end

  private
    # Changing the sign-in email needs the current password. A given password
    # is checked by has_secure_password's password_challenge validation.
    def email_change_missing_password?
      return false unless @profile.email_address_changed?

      challenge = params.dig(:user, :password_challenge).to_s
      @profile.password_challenge = challenge if challenge.present?
      challenge.blank?
    end
end
