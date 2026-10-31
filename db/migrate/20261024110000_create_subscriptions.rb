# A paid plan as the payment provider sees it. The provider is the source of
# truth; webhooks keep this copy (and users.plan) in step.
class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :external_id, null: false
      t.string :customer_id
      t.string :plan, null: false, default: "pro"
      t.string :interval, null: false
      t.string :currency, null: false
      t.string :status, null: false
      t.datetime :current_period_end
      t.boolean :cancel_at_period_end, null: false, default: false
      t.timestamps
    end
    add_index :subscriptions, %i[provider external_id], unique: true
  end
end
