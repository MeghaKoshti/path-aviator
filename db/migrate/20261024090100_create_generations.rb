# One row per AI call: a new path or a regeneration ("path", counted against
# the monthly quota) or a broken link's substitute ("link_replacement", only
# against the daily cost cap). Rows outlive their path, so deleting a path
# never gives quota back.
class CreateGenerations < ActiveRecord::Migration[8.1]
  def change
    create_table :generations do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :learning_path, foreign_key: { on_delete: :nullify }
      t.string :kind, null: false, default: "path"
      t.datetime :failed_at
      t.timestamps
    end
    add_index :generations, %i[user_id created_at]
    add_index :generations, :created_at
  end
end
