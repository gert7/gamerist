class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.integer :user_id
      t.string :countrycode
      t.string :nickname
      t.date :dob
      t.string :firstname
      t.string :lastname
      t.string :paypaladdress

      t.timestamps
    end
  end
end
