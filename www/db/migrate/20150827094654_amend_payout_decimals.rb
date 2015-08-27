class AmendPayoutDecimals < ActiveRecord::Migration
  def change
    change_column :payouts, :subtotal, :decimal, precision: 16, scale: 2
    change_column :payouts, :total, :decimal, precision: 16, scale: 2
    change_column :payouts, :margin, :decimal, precision: 16, scale: 2
  end
end
