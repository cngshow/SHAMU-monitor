class JobMetadatas < ActiveRecord::Migration
  def self.up
    create_table :job_metadatas  do |t|
      t.string :job_code, :null => false
      t.string :short_desc, :null => true, :limit => 50
      t.text :description
      t.boolean :active
      t.boolean :suspend
      t.datetime :stop
      t.datetime :resume
      t.text :email_to, :null => true
      t.text :email_cc, :null => true
      t.boolean :email_result, :null => false, :default => false
      t.string :email_content_type, :null => false, :default => 'text/plain', :limit => 50
      t.boolean :incl_attachment, :null => false, :default => false
      t.text :attachment_path, :null => true
      t.integer :stale_after_min, :unique => false, :null => false, :default => 30
      t.boolean :enabled_as_service, :boolean, :null => false, :default => false
      t.boolean :track_status_change, :null => false, :default => false
      t.boolean :email_on_status_change_only, :null => false, :default => false
      t.integer :minutes_between_status_alert, :null => false, :default => 60

      #status columns in the log apply to jobmetadatas that are tracking status (:track_status_change = true)
      t.integer :max_execution_minutes, :null => false, :default => 60
      t.datetime :last_email_sent, :null => true

      #introscope related columns
      t.boolean :introscope_enabled, :null => false, :default => false
      t.boolean :use_introscope_job_code, :null => false, :default => false
      t.string :introscope_job_code, :null => true, :limit => 50
      t.boolean :use_introscope_short_desc, :null => false, :default => false
      t.string :introscope_short_desc, :null => true, :limit => 50
      t.boolean :use_introscope_long_desc, :null => false, :default => false
      t.text :introscope_long_desc, :null => true

      t.timestamps

    end
    add_index :job_metadatas, :job_code, :unique => true, :name=>'idx_jmd_job_code' #main search
  end

  def self.down
    remove_index :job_metadatas, :name=>'idx_jmd_job_code' #main search
    drop_table :job_metadatas 
  end
end