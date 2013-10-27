class CreateServers < ActiveRecord::Migration
  def change
    create_table :servers do |t|
      t.integer :number
      t.string :server_address
      t.string :dispatch_address
      t.integer :dispatch_version

      t.timestamps
    end
  end
end
