class SystemProps < ActiveRecord::Migration
  def self.up
    create_table :system_props do |t|
      t.string :key
      t.string :value
      t.timestamps
    end
  end

  def self.down
    drop_table :system_props
  end
end
