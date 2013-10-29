class CreateMaps < ActiveRecord::Migration
  def change
    create_table :maps do |t|
      t.string :prefix
      t.string :name
      t.integer :game_id

      t.timestamps
    end
  end
end
