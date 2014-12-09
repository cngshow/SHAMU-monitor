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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111101180004) do

  create_table "escalations", :force => true do |t|
    t.integer  "job_metadata_id", :precision => 38, :scale => 0,                    :null => false
    t.string   "color_name",                                                        :null => false
    t.integer  "end_min",         :precision => 38, :scale => 0
    t.integer  "priority",        :precision => 38, :scale => 0,                    :null => false
    t.text     "email_preamble"
    t.text     "email_to"
    t.text     "email_cc"
    t.boolean  "suppress_email",  :precision => 1,  :scale => 0, :default => false, :null => false
    t.boolean  "enabled",         :precision => 1,  :scale => 0, :default => false, :null => false
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
  end

  create_table "job_log_entries", :force => true do |t|
    t.string   "job_code",                                                                            :null => false
    t.string   "run_by",                                                       :default => "SYSTEM",  :null => false
    t.datetime "start_time",                                                                          :null => false
    t.datetime "finish_time"
    t.text     "job_result"
    t.text     "email_to"
    t.text     "email_cc"
    t.boolean  "email_sent",                    :precision => 1,  :scale => 0, :default => false,     :null => false
    t.string   "run_status",                                                   :default => "Pending", :null => false
    t.boolean  "status_changed",                :precision => 1,  :scale => 0, :default => false,     :null => false
    t.string   "run_data"
    t.string   "introscope_data"
    t.string   "status",          :limit => 50
    t.integer  "status_cnt",                    :precision => 38, :scale => 0
    t.datetime "created_at",                                                                          :null => false
    t.datetime "updated_at",                                                                          :null => false
  end

  add_index "job_log_entries", ["job_code", "finish_time", "status"], :name => "idx_jle_last_known_status"
  add_index "job_log_entries", ["job_code", "finish_time"], :name => "idx_jle_end"
  add_index "job_log_entries", ["job_code", "start_time"], :name => "idx_jle_start"
  add_index "job_log_entries", ["job_code", "status_changed"], :name => "idx_jle_status_changed"

  create_table "job_metadatas", :force => true do |t|
    t.string   "job_code",                                                                                            :null => false
    t.string   "short_desc",                   :limit => 50
    t.text     "description"
    t.boolean  "active",                                     :precision => 1,  :scale => 0
    t.boolean  "suspend",                                    :precision => 1,  :scale => 0
    t.datetime "stop"
    t.datetime "resume"
    t.text     "email_to"
    t.text     "email_cc"
    t.boolean  "email_result",                               :precision => 1,  :scale => 0, :default => false,        :null => false
    t.string   "email_content_type",           :limit => 50,                                :default => "text/plain", :null => false
    t.boolean  "incl_attachment",                            :precision => 1,  :scale => 0, :default => false,        :null => false
    t.text     "attachment_path"
    t.integer  "stale_after_min",                            :precision => 38, :scale => 0, :default => 30,           :null => false
    t.boolean  "enabled_as_service",                         :precision => 1,  :scale => 0, :default => false,        :null => false
    t.boolean  "boolean",                                    :precision => 1,  :scale => 0, :default => false,        :null => false
    t.boolean  "track_status_change",                        :precision => 1,  :scale => 0, :default => false,        :null => false
    t.boolean  "email_on_status_change_only",                :precision => 1,  :scale => 0, :default => false,        :null => false
    t.integer  "minutes_between_status_alert",               :precision => 38, :scale => 0, :default => 60,           :null => false
    t.integer  "max_execution_minutes",                      :precision => 38, :scale => 0, :default => 60,           :null => false
    t.datetime "last_email_sent"
    t.boolean  "introscope_enabled",                         :precision => 1,  :scale => 0, :default => false,        :null => false
    t.boolean  "use_introscope_job_code",                    :precision => 1,  :scale => 0, :default => false,        :null => false
    t.string   "introscope_job_code",          :limit => 50
    t.boolean  "use_introscope_short_desc",                  :precision => 1,  :scale => 0, :default => false,        :null => false
    t.string   "introscope_short_desc",        :limit => 50
    t.boolean  "use_introscope_long_desc",                   :precision => 1,  :scale => 0, :default => false,        :null => false
    t.text     "introscope_long_desc"
    t.datetime "created_at",                                                                                          :null => false
    t.datetime "updated_at",                                                                                          :null => false
  end

  add_index "job_metadatas", ["job_code"], :name => "idx_jmd_job_code", :unique => true

  create_table "system_props", :force => true do |t|
    t.string   "key"
    t.string   "value"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                                 :default => "",    :null => false
    t.string   "encrypted_password",                                    :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :precision => 38, :scale => 0, :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                                               :null => false
    t.datetime "updated_at",                                                               :null => false
    t.boolean  "administrator",          :precision => 1,  :scale => 0, :default => false
    t.string   "username"
    t.datetime "last_activity_datetime"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "idx_user_reset_password", :unique => true

end
