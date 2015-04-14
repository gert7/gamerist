class CreateSteamids < ActiveRecord::Migration
  def change
    create_table :steamids do |t|
      t.string :steamid
      t.integer :user_id

      t.timestamps
    end
  end
end
