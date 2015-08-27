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
  before_save do
    self.subtotal = BigDecimal.new(self.points.to_s)
    self.total    = self.subtotal
    self.margin   = self.total - self.subtotal
  end
end
