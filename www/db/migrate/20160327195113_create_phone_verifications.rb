class CreatePhoneVerifications < ActiveRecord::Migration
  def change
    create_table :phone_verifications do |t|
      t.integer :user_id
      t.string :code
      t.integer :state
      t.string :phonenumber

      t.timestamps null: false
    end
  end
end
