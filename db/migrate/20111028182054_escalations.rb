class Escalations < ActiveRecord::Migration
  def self.up
    create_table :escalations do |t|
      t.integer :job_metadata_id, :null => false
      t.string :color_name, :null => false
      t.integer :end_min, :null => true
      t.integer :priority, :null => false
      t.text :email_preamble, :null => true
      t.text :email_to, :null => true
      t.text :email_cc, :null => true
      t.boolean :suppress_email, :null => false, :default => false
      t.boolean :enabled, :null => false, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :escalations
  end
end
