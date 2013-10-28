class Ruleset < ActiveRecord::Base
	has_many :rooms
	belongs_to :game
end
