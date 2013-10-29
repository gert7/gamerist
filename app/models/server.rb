class Server < ActiveRecord::Base
	belongs_to :game
	has_one :room
end
