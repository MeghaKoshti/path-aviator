class AddJobPostToLearningGoals < ActiveRecord::Migration[8.1]
  def change
    add_column :learning_goals, :job_post, :text
    add_column :learning_goals, :target_date, :date
    add_column :learning_paths, :skills, :json, null: false, default: []
  end
end
