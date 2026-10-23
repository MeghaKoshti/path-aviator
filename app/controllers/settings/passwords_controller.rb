class Settings::PasswordsController < SettingsController
  def update
    @password_change = User.find(Current.user.id)
    attributes = params.expect(user: [ :password_challenge, :password, :password_confirmation ])
    attributes[:password_challenge] = attributes[:password_challenge].to_s

    # has_secure_password ignores a blank new password, so ask for one explicitly.
    if attributes[:password].blank?
      @password_change.errors.add(:password, :blank)
      render_settings status: :unprocessable_entity
    elsif @password_change.update(attributes)
      # Anyone signed in elsewhere with the old password is signed out.
      @password_change.sessions.where.not(id: Current.session.id).destroy_all
      redirect_to settings_path, notice: "Password changed. Other devices have been signed out.", status: :see_other
    else
      render_settings status: :unprocessable_entity
    end
  end
end
