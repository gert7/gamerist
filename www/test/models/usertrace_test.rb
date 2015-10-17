# == Schema Information
#
# Table name: usertraces
#
#  id        :integer          not null, primary key
#  user_id   :integer
#  timestamp :datetime
#  ipaddress :string(255)
#

require 'test_helper'

class UsertraceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
