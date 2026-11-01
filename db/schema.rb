# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_31_153844) do
  create_table "data_exports", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "status", default: "pending", null: false
    t.binary "archive"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_data_exports_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.integer "user_id"
    t.string "name", null: false
    t.json "properties", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["name", "created_at"], name: "index_events_on_name_and_created_at"
    t.index ["user_id", "name"], name: "index_events_on_user_id_and_name"
  end

  create_table "generations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "learning_path_id"
    t.string "kind", default: "path", null: false
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_generations_on_created_at"
    t.index ["learning_path_id"], name: "index_generations_on_learning_path_id"
    t.index ["user_id", "created_at"], name: "index_generations_on_user_id_and_created_at"
  end

  create_table "learning_goals", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "topic", null: false
    t.integer "current_level", default: 0, null: false
    t.integer "hours_per_week", null: false
    t.text "goal_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "job_post"
    t.date "target_date"
    t.index ["user_id"], name: "index_learning_goals_on_user_id"
  end

  create_table "learning_paths", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "learning_goal_id", null: false
    t.string "title"
    t.text "summary"
    t.integer "status", default: 0, null: false
    t.string "error_message"
    t.text "raw_response"
    t.integer "path_steps_count", default: 0, null: false
    t.integer "completed_steps_count", default: 0, null: false
    t.datetime "generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "share_token"
    t.integer "input_tokens"
    t.integer "output_tokens"
    t.integer "thinking_tokens"
    t.json "skills", default: [], null: false
    t.string "certificate_token"
    t.datetime "certificate_issued_at"
    t.index ["certificate_token"], name: "index_learning_paths_on_certificate_token", unique: true
    t.index ["learning_goal_id"], name: "index_learning_paths_on_learning_goal_id", unique: true
    t.index ["share_token"], name: "index_learning_paths_on_share_token", unique: true
    t.index ["user_id"], name: "index_learning_paths_on_user_id"
  end

  create_table "path_steps", force: :cascade do |t|
    t.integer "learning_path_id", null: false
    t.integer "position", null: false
    t.string "title", null: false
    t.text "description"
    t.string "resource_type", null: false
    t.string "resource_url", null: false
    t.integer "estimated_minutes", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "note"
    t.string "link_status", default: "unchecked", null: false
    t.datetime "link_checked_at"
    t.string "evidence_url"
    t.index ["learning_path_id", "position"], name: "index_path_steps_on_learning_path_id_and_position", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "provider", null: false
    t.string "external_id", null: false
    t.string "customer_id"
    t.string "plan", default: "pro", null: false
    t.string "interval", null: false
    t.string "currency", null: false
    t.string "status", null: false
    t.datetime "current_period_end"
    t.boolean "cancel_at_period_end", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "past_due_at"
    t.datetime "last_event_at"
    t.index ["provider", "external_id"], name: "index_subscriptions_on_provider_and_external_id", unique: true
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "plan", default: "free", null: false
    t.datetime "email_verified_at"
    t.string "time_zone", default: "UTC", null: false
    t.boolean "weekly_digest", default: true, null: false
    t.datetime "weekly_digest_sent_at"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "webhook_events", force: :cascade do |t|
    t.string "provider", null: false
    t.string "event_id", null: false
    t.string "event_type"
    t.text "payload"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "event_id"], name: "index_webhook_events_on_provider_and_event_id", unique: true
  end

  add_foreign_key "data_exports", "users"
  add_foreign_key "events", "users", on_delete: :nullify
  add_foreign_key "generations", "learning_paths", on_delete: :nullify
  add_foreign_key "generations", "users"
  add_foreign_key "learning_goals", "users"
  add_foreign_key "learning_paths", "learning_goals"
  add_foreign_key "learning_paths", "users"
  add_foreign_key "path_steps", "learning_paths"
  add_foreign_key "sessions", "users"
  add_foreign_key "subscriptions", "users"
end
