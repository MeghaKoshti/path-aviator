class CreateLearningGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :learning_goals do |t|
      t.references :user, null: false, foreign_key: true
      t.string :topic, null: false
      t.integer :current_level, null: false, default: 0
      t.integer :hours_per_week, null: false
      t.text :goal_description

      t.timestamps
    end
  end
end
