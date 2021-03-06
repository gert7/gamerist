class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.integer :state
      t.references :user, index: true
      t.integer :lastref
      t.integer :kind
      t.integer :detail
      t.integer :amount
      t.integer :balance_u
      t.integer :balance_r

      t.timestamps
    end
  end
end
