# == Schema Information
#
# Table name: phone_verifications
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  code        :string
#  state       :integer
#  phonenumber :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'test_helper'

class PhoneVerificationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
