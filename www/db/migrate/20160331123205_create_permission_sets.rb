class CreatePermissionSets < ActiveRecord::Migration
  def change
    create_table :permission_sets do |t|
      t.integer :user_id
      t.integer :permissions

      t.timestamps null: false
    end
  end
end
