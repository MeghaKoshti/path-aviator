class CreateEventsAndDataExports < ActiveRecord::Migration[8.1]
  def change
    # First-party product analytics. A deleted user's events stay, without them.
    create_table :events do |t|
      t.references :user, index: false, foreign_key: { on_delete: :nullify } # see the [user_id, name] index
      t.string :name, null: false
      t.json :properties, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :events, [ :name, :created_at ]
    add_index :events, [ :user_id, :name ]

    # "Download my data": the archive is small, so it lives in the row.
    create_table :data_exports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.binary :archive
      t.timestamps
    end
  end
end
