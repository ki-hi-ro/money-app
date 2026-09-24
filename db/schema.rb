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

ActiveRecord::Schema[7.0].define(version: 2026_09_21_020000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "asset_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.bigint "balance", default: 0, null: false
    t.date "balance_on", null: false
    t.string "unit", default: "円", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_asset_accounts_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_asset_accounts_on_user_id"
  end

  create_table "asset_snapshots", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "month", null: false
    t.jsonb "balances", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "month"], name: "index_asset_snapshots_on_user_id_and_month", unique: true
    t.index ["user_id"], name: "index_asset_snapshots_on_user_id"
  end

  create_table "cash_entries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date"
    t.string "kind", null: false
    t.bigint "amount"
    t.string "category"
    t.string "description", null: false
    t.string "payment_method"
    t.string "status", default: "完了", null: false
    t.text "notes"
    t.bigint "card_confirmed_amount"
    t.string "source_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "payment_card_id"
    t.string "payment_type", default: "other", null: false
    t.date "statement_start_on"
    t.date "statement_end_on"
    t.index ["payment_card_id"], name: "index_cash_entries_on_payment_card_id"
    t.index ["user_id", "date"], name: "index_cash_entries_on_user_id_and_date"
    t.index ["user_id", "source_key"], name: "index_cash_entries_on_user_id_and_source_key", unique: true
    t.index ["user_id"], name: "index_cash_entries_on_user_id"
  end

  create_table "dialies", force: :cascade do |t|
    t.date "date"
    t.string "title"
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_dialies_on_user_id"
  end

  create_table "money_tasks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.date "due_on"
    t.time "due_time"
    t.boolean "completed", default: false, null: false
    t.string "source_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "source_key"], name: "index_money_tasks_on_user_id_and_source_key", unique: true
    t.index ["user_id"], name: "index_money_tasks_on_user_id"
  end

  create_table "payment_cards", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.integer "closing_day", default: 27, null: false
    t.integer "payment_month_offset", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_payment_cards_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_payment_cards_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date"
    t.integer "price"
    t.bigint "user_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "monthly_card_budget", precision: 20, scale: 6, default: "0.0", null: false
    t.bigint "monthly_living_budget"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "asset_accounts", "users"
  add_foreign_key "asset_snapshots", "users"
  add_foreign_key "cash_entries", "payment_cards"
  add_foreign_key "cash_entries", "users"
  add_foreign_key "dialies", "users"
  add_foreign_key "money_tasks", "users"
  add_foreign_key "payment_cards", "users"
  add_foreign_key "posts", "users"
end
