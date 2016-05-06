# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160506181737) do

  create_table "accounts", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "countrycode"
    t.string   "nickname"
    t.date     "dob"
    t.string   "firstname"
    t.string   "lastname"
    t.string   "paypaladdress"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"

  create_table "admins", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admins", ["email"], name: "index_admins_on_email", unique: true
  add_index "admins", ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true

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
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "maxmind_geolite_country", id: false, force: :cascade do |t|
    t.string  "start_ip"
    t.string  "end_ip"
    t.integer "start_ip_num", limit: 8, null: false
    t.integer "end_ip_num",   limit: 8, null: false
    t.string  "country_code",           null: false
    t.string  "country",                null: false
  end

  add_index "maxmind_geolite_country", ["start_ip_num"], name: "index_maxmind_geolite_country_on_start_ip_num", unique: true

  create_table "modifiers", force: :cascade do |t|
    t.string   "key"
    t.string   "value"
    t.boolean  "active"
    t.boolean  "recent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payouts", force: :cascade do |t|
    t.string   "batchid"
    t.integer  "points"
    t.decimal  "subtotal",   precision: 16, scale: 2
    t.decimal  "total",      precision: 16, scale: 2
    t.decimal  "margin",     precision: 16, scale: 2
    t.string   "currency"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "user_id"
  end

  create_table "paypals", force: :cascade do |t|
    t.decimal  "amount",     precision: 8, scale: 2
    t.decimal  "subtotal",   precision: 8, scale: 2
    t.decimal  "tax",        precision: 8, scale: 2
    t.integer  "state"
    t.integer  "user_id"
    t.string   "sid"
    t.string   "redirect"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "country"
  end

  create_table "permission_sets", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "permissions"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "phone_verifications", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "code"
    t.integer  "state"
    t.string   "phonenumber"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "rooms", force: :cascade do |t|
    t.integer  "state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "rules"
  end

  create_table "steamids", force: :cascade do |t|
    t.string   "steamid"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer  "state"
    t.integer  "user_id"
    t.integer  "lastref"
    t.integer  "kind"
    t.integer  "detail"
    t.integer  "amount"
    t.integer  "balance_u"
    t.integer  "balance_r"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "transactions", ["user_id"], name: "index_transactions_on_user_id"

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "relevantgames"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

  create_table "usertraces", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "timestamp"
    t.string   "ipaddress"
  end

end
