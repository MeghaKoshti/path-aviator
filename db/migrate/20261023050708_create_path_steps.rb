class CreatePathSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :path_steps do |t|
      t.references :learning_path, null: false, foreign_key: true, index: false
      t.integer :position, null: false
      t.string :title, null: false
      t.text :description
      t.string :resource_type, null: false
      t.string :resource_url, null: false
      t.integer :estimated_minutes, null: false
      t.datetime :completed_at

      t.timestamps
    end

    # Also serves lookups by learning_path_id, so no separate index is needed.
    add_index :path_steps, [ :learning_path_id, :position ], unique: true
  end
end
