class AddUserToPayout < ActiveRecord::Migration
  def change
    add_column :payouts, :user_id, :integer
  end
end
