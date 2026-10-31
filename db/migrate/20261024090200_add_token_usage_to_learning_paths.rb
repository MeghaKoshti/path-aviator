class AddTokenUsageToLearningPaths < ActiveRecord::Migration[8.1]
  def change
    add_column :learning_paths, :input_tokens, :integer
    add_column :learning_paths, :output_tokens, :integer
    add_column :learning_paths, :thinking_tokens, :integer
  end
end
