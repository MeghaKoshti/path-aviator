# Builds a "Download my data" archive in the background and tells the
# settings page when it's ready.
class DataExportJob < ApplicationJob
  queue_as :default
  discard_on ActiveJob::DeserializationError

  def perform(data_export)
    data_export.update!(archive: DataExportBuilder.new(data_export.user).archive, status: :ready)
  rescue StandardError
    data_export.update!(status: :failed)
    raise
  ensure
    broadcast(data_export)
  end

  private
    def broadcast(data_export)
      return unless DataExport.exists?(data_export.id)

      user = data_export.user
      Time.use_zone(user.zone) do
        Turbo::StreamsChannel.broadcast_replace_to [ user, :data_exports ],
          target: "data_export", partial: "settings/data_export", locals: { data_export: data_export }
      end
    end
end
