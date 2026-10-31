class AddNoteToPathSteps < ActiveRecord::Migration[8.1]
  def change
    add_column :path_steps, :note, :text
  end
end
