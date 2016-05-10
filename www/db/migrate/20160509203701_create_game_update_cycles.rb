class CreateGameUpdateCycles < ActiveRecord::Migration
  def change
    create_table :game_update_cycles do |t|
      t.string :game
      t.integer :state

      t.timestamps null: false
    end
  end
end
