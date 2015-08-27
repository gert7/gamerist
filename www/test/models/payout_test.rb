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

require 'test_helper'

class PayoutTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
