class CreatePaypals < ActiveRecord::Migration
  def change
    create_table :paypals do |t|
      t.decimal :amount, precision: 8, scale: 2
      t.decimal :subtotal, precision: 8, scale: 2
      t.decimal :tax, precision: 8, scale: 2
      t.integer :state
      t.integer :user_id
      t.string :sid
      t.string :redirect

      t.timestamps
    end
  end
end
