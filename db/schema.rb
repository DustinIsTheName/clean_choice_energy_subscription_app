# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20181004204431) do

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "events", force: :cascade do |t|
    t.string   "name"
    t.string   "event_type"
    t.text     "event_lines"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "user_id"
  end

  create_table "imports", force: :cascade do |t|
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "transaction_count"
    t.integer  "user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.text     "address"
    t.string   "cc_number"
    t.string   "expiration"
    t.string   "external_id"
    t.integer  "product",              limit: 8
    t.string   "payment_service"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "external_customer_id"
    t.integer  "job_id"
    t.integer  "amount"
    t.string   "full_name"
  end

  create_table "transactions", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.integer  "product",         limit: 8
    t.integer  "amount"
    t.string   "cc_number"
    t.boolean  "status"
    t.text     "error_codes"
    t.integer  "import_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.boolean  "no_retry"
    t.integer  "subscription_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "access"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "first_name"
    t.string   "last_name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
