# "Download my data": DataExportJob fills in the archive (a .tar.gz with a
# JSON file of everything and a Markdown file per path).
class DataExport < ApplicationRecord
  belongs_to :user

  enum :status, { pending: "pending", ready: "ready", failed: "failed" }, default: :pending

  def filename
    "path-aviator-export-#{created_at.to_date.iso8601}.tar.gz"
  end
end
