class AddRulesToRooms < ActiveRecord::Migration
  def change
    remove_column :rooms, :rules
    add_column :rooms, :rules, :text
  end
end
