# == Schema Information
#
# Table name: payouts
#
#  id         :integer          not null, primary key
#  batchid    :string
#  points     :integer
#  subtotal   :decimal(16, 2)
#  total      :decimal(16, 2)
#  margin     :decimal(16, 2)
#  currency   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#

require 'test_helper'

class PayoutTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
