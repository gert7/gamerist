class Room < ActiveRecord::Base
	belongs_to :owner, class_name: 'User'
	has_many :users

	belongs_to :ruleset
	belongs_to :server
	belongs_to :game
end
