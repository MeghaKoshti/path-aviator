class AddTimeZoneAndWeeklyDigestToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :time_zone, :string, null: false, default: "UTC"
    add_column :users, :weekly_digest, :boolean, null: false, default: true
    add_column :users, :weekly_digest_sent_at, :datetime
  end
end
