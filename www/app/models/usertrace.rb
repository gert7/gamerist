# == Schema Information
#
# Table name: usertraces
#
#  id        :integer          not null, primary key
#  user_id   :integer
#  timestamp :datetime
#  ipaddress :string(255)
#

class Usertrace < ActiveRecord::Base
  belongs_to :user, inverse_of: :usertraces
end

