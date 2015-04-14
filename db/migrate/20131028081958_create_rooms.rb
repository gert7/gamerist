class CreateRooms < ActiveRecord::Migration
  def change
    create_table :rooms do |t|
      t.integer :state
      t.text    :rules

      t.timestamps
    end
  end
end
