class FixColumnName < ActiveRecord::Migration
  def change
    rename_column :rooms, :owner, :owner_id
  end
end
