# == Schema Information
#
# Table name: servers
#
#  id               :integer          not null, primary key
#  number           :integer
#  server_address   :string(255)
#  dispatch_address :string(255)
#  dispatch_version :integer
#  created_at       :datetime
#  updated_at       :datetime
#

class Server < ActiveRecord::Base
	belongs_to :game
	has_one :room
end
