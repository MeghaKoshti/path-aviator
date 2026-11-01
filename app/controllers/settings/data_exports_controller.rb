# "Download my data" in Settings: create starts a fresh export (replacing
# the last one), show downloads it once it's ready.
class Settings::DataExportsController < SettingsController
  def create
    Current.user.data_exports.destroy_all
    DataExportJob.perform_later(Current.user.data_exports.create!)
    redirect_to settings_path(anchor: "data_export"), notice: "Preparing your data. The download appears here in a moment.", status: :see_other
  end

  def show
    data_export = Current.user.data_exports.ready.order(:created_at).last!
    send_data data_export.archive, filename: data_export.filename, type: "application/gzip", disposition: "attachment"
  end
end
