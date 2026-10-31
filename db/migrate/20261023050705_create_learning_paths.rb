class CreateLearningPaths < ActiveRecord::Migration[8.0]
  def change
    create_table :learning_paths do |t|
      t.references :user, null: false, foreign_key: true
      t.references :learning_goal, null: false, foreign_key: true, index: { unique: true }
      t.string :title
      t.text :summary
      t.integer :status, null: false, default: 0
      t.string :error_message
      t.text :raw_response
      t.integer :path_steps_count, null: false, default: 0
      t.integer :completed_steps_count, null: false, default: 0
      t.datetime :generated_at

      t.timestamps
    end
  end
end
