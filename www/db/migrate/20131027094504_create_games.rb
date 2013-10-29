class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :prettyname
      t.string :enum

      t.timestamps
    end
  end
end
