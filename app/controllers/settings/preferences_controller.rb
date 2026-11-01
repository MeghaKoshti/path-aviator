class Settings::PreferencesController < SettingsController
  def update
    @preferences = User.find(Current.user.id)

    if @preferences.update(params.expect(user: [ :time_zone, :weekly_digest ]))
      redirect_to settings_path(anchor: "preferences"), notice: "Preferences saved.", status: :see_other
    else
      render_settings status: :unprocessable_entity
    end
  end
end
