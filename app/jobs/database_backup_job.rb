# Nightly copy of the main SQLite database (config/recurring.yml). Does
# nothing unless BACKUP_DIR is set, e.g. a second Docker volume or a mounted
# disk. VACUUM INTO writes a consistent, compacted snapshot while the app
# keeps running. The newest BACKUP_KEEP copies (default 7) are kept.
#
# An S3-compatible store can be added later: upload the file this job writes.
class DatabaseBackupJob < ApplicationJob
  queue_as :default

  def perform(dir: ENV["BACKUP_DIR"], keep: ENV.fetch("BACKUP_KEEP", 7).to_i, now: Time.current)
    return if dir.blank?

    FileUtils.mkdir_p(dir)
    target = File.join(dir, "#{Rails.env}-#{now.utc.strftime("%Y%m%d-%H%M%S")}.sqlite3")
    ActiveRecord::Base.connection.execute("VACUUM INTO #{ActiveRecord::Base.connection.quote(target)}")
    prune(dir, keep)
    target
  end

  private
    def prune(dir, keep)
      backups = Dir.glob(File.join(dir, "#{Rails.env}-*.sqlite3")).sort
      FileUtils.rm(backups.first([ backups.size - keep, 0 ].max))
    end
end
