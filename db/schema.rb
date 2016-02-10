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

ActiveRecord::Schema.define(version: 20160107002002) do

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

  create_table "mail_messages", force: :cascade do |t|
    t.string   "subject",                      null: false
    t.text     "body",                         null: false
    t.string   "environment"
    t.string   "status"
    t.string   "severity",                     null: false
    t.datetime "message_date",                 null: false
    t.boolean  "whitelisted",  default: false, null: false
    t.integer  "zabbix_id"
    t.integer  "jira_id"
    t.string   "jira_key"
    t.binary   "mail_message",                 null: false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mail_messages", ["deleted_at"], name: "index_mail_messages_on_deleted_at"
  add_index "mail_messages", ["jira_id"], name: "index_mail_messages_on_jira_id"
  add_index "mail_messages", ["jira_key"], name: "index_mail_messages_on_jira_key"
  add_index "mail_messages", ["zabbix_id"], name: "index_mail_messages_on_zabbix_id"

end
