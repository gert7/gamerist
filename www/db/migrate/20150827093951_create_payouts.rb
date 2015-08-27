class CreatePayouts < ActiveRecord::Migration
  def change
    create_table :payouts do |t|
      t.string :batchid
      t.integer :points
      t.decimal :subtotal
      t.decimal :total
      t.decimal :margin
      t.string :currency

      t.timestamps null: false
    end
  end
end
