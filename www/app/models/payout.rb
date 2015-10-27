# == Schema Information
#
# Table name: payouts
#
#  id         :integer          not null, primary key
#  batchid    :string(255)
#  points     :integer
#  subtotal   :decimal(16, 2)
#  total      :decimal(16, 2)
#  margin     :decimal(16, 2)
#  currency   :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Payout < ActiveRecord::Base
  after_initialize :calculate_results
  before_save      :calculate_results
  
  belongs_to :user, inverse_of: :payouts
  
  def calculate_results
    self.subtotal = BigDecimal.new(self.points.to_s)
    self.total    = self.subtotal - BigDecimal.new(Modifier.get("FIXED_WITHDRAWAL_FEE"))
    self.margin   = self.total - self.subtotal
    self.currency = "EUR"
  end
  
  def get_paydata
    { subtotal: self.subtotal, total: self.total, currency: self.currency, modifiers: [{name: "Fixed withdrawal fee", amount: 0 - Modifier.get("FIXED_WITHDRAWAL_FEE").to_i}] }
  end
end

