class AddStateTrackingToSubscriptions < ActiveRecord::Migration[8.1]
  def change
    # When the first failed payment came in; Pro is kept for a grace period.
    add_column :subscriptions, :past_due_at, :datetime
    # Time of the newest event applied, so late, out-of-order ones are skipped.
    add_column :subscriptions, :last_event_at, :datetime
    add_index :subscriptions, :status
  end
end
