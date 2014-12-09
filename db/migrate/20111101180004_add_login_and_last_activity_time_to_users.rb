class AddLoginAndLastActivityTimeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :username, :string
    add_column :users, :last_activity_datetime, :datetime, :null => true
  end
end
