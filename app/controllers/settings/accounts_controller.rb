class Settings::AccountsController < SettingsController
  def destroy
    if confirmed?
      # Sessions, paths, steps and goals go with the user (dependent: :destroy).
      Current.user.destroy!
      cookies.delete(:session_id)
      redirect_to root_path, notice: "Your account and all your paths have been deleted.", status: :see_other
    else
      @deletion_error = "Type DELETE or your email address to confirm."
      render_settings status: :unprocessable_entity
    end
  end

  private
    def confirmed?
      confirmation = params[:confirmation].to_s.strip
      confirmation == "DELETE" || confirmation.casecmp?(Current.user.email_address)
    end
end
