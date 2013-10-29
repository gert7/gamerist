class CreateRooms < ActiveRecord::Migration
  def change
    create_table :rooms do |t|
      t.integer :owner
      t.integer :game_id
      t.integer :ruleset_id
      t.integer :state
      t.integer :server_id

      t.timestamps
    end
  end
end
