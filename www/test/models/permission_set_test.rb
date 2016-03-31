# == Schema Information
#
# Table name: permission_sets
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  permissions :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'test_helper'

class PermissionSetTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
