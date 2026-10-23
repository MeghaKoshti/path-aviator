class AddShareTokenToLearningPaths < ActiveRecord::Migration[8.1]
  def change
    # nil means the path is private; a token means it can be viewed at /p/:token.
    add_column :learning_paths, :share_token, :string
    add_index :learning_paths, :share_token, unique: true
  end
end
