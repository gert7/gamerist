# == Schema Information
#
# Table name: modifiers
#
#  id         :integer          not null, primary key
#  key        :string(255)
#  value      :string(255)
#  active     :boolean
#  recent     :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class ModifierTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
