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

ActiveRecord::Schema.define(version: 20150812163830) do

  create_table "bookmarks", force: :cascade do |t|
    t.integer  "user_id",                   null: false
    t.string   "document_id",   limit: 255
    t.string   "title",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type",     limit: 255
    t.string   "document_type", limit: 255
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id"

  create_table "content_blocks", force: :cascade do |t|
    t.string   "title",      limit: 255, null: false
    t.integer  "user_id",                null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "content_blocks", ["title"], name: "index_content_blocks_on_title"

  create_table "models", force: :cascade do |t|
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

  add_index "models", ["email"], name: "index_models_on_email", unique: true
  add_index "models", ["reset_password_token"], name: "index_models_on_reset_password_token", unique: true

  create_table "reports", force: :cascade do |t|
    t.string   "name",         limit: 255, null: false
    t.string   "category",     limit: 255, null: false
    t.datetime "generated_on"
    t.integer  "user_id"
    t.text     "options"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "reports", ["category"], name: "index_reports_on_category"

  create_table "roles", force: :cascade do |t|
    t.string   "role_sym",   limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["role_sym"], name: "index_roles_on_role_sym", unique: true

  create_table "roles_users", id: false, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
  end

  add_index "roles_users", ["role_id"], name: "index_roles_users_on_role_id"
  add_index "roles_users", ["user_id"], name: "index_roles_users_on_user_id"

  create_table "searches", force: :cascade do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type",    limit: 255
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id"

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255, null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at"

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type", limit: 255
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], name: "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", force: :cascade do |t|
    t.string "name", limit: 255
  end

  create_table "users", force: :cascade do |t|
    t.string   "first_name",             limit: 255
    t.string   "last_name",              limit: 255
    t.boolean  "admin"
    t.string   "uid",                    limit: 255,                 null: false
    t.string   "wind_login",             limit: 255
    t.string   "email",                  limit: 255
    t.string   "encrypted_password",     limit: 255
    t.string   "persistence_token",      limit: 255
    t.integer  "sign_in_count",                      default: 0,     null: false
    t.text     "last_search_url"
    t.datetime "last_sign_in_at"
    t.datetime "last_request_at"
    t.datetime "current_sign_in_at"
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "current_sign_in_ip",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "cul_staff",                          default: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string   "provider"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["last_request_at"], name: "index_users_on_last_request_at"
  add_index "users", ["persistence_token"], name: "index_users_on_persistence_token"
  add_index "users", ["provider"], name: "index_users_on_provider"
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  add_index "users", ["uid"], name: "index_users_on_uid"
  add_index "users", ["wind_login"], name: "index_users_on_wind_login"

end
