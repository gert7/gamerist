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

# Permissions list:
# 0 - none
# 1 - administrator

class PermissionSet < ActiveRecord::Base
  belongs_to :user, inverse_of: :permission_set
end
