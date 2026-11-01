class AddLinkStatusToPathSteps < ActiveRecord::Migration[8.1]
  def change
    add_column :path_steps, :link_status, :string, null: false, default: "unchecked"
    add_column :path_steps, :link_checked_at, :datetime
  end
end
