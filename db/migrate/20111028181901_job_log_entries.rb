class JobLogEntries < ActiveRecord::Migration
  def self.up
    create_table :job_log_entries do |t|
      t.string :job_code, :null => false
      t.string :run_by, :null => false, :default => 'SYSTEM'
      t.datetime :start_time, :null => false
      t.datetime :finish_time, :null => true
      t.text :job_result, :null => true
      t.text :email_to, :null => true
      t.text :email_cc, :null => true
      t.boolean :email_sent, :null => false, :default => false
      t.string :run_status, :null => false, :default => 'Pending'
      t.boolean :status_changed, :null => false, :default => false
      t.string :run_data, :null => true
      t.string :introscope_data, :null => true
      t.string :status, :null => true, :limit => 50
      t.integer :status_cnt, :null => true
      t.timestamps
    end

    add_index :job_log_entries, [:job_code, :start_time], :unique => false, :name=>'idx_jle_start'
    add_index :job_log_entries, [:job_code, :finish_time], :unique => false, :name=>'idx_jle_end'
    add_index :job_log_entries, [:job_code, :status_changed], :name=>'idx_jle_status_changed'

    #last known status index -- job_code(jc).finished(true).tracked(status_known).order("finish_time desc")
    # this has not been tested. An index with the name below was added directly to the database
    add_index(:job_log_entries, [:job_code, :finish_time, :status], :name=>'idx_jle_last_known_status', :order => {:finish_time => :desc, :status => :asc})

  end

  def self.down
    remove_index :job_log_entries, :name=>'idx_jle_start'
    remove_index :job_log_entries, :name=>'idx_jle_end'
    remove_index :job_log_entries, :name=>'idx_jle_status_changed'
    drop_table :job_log_entries
  end
end
