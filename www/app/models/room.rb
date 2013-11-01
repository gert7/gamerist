class Room < ActiveRecord::Base
  STATE_DRAFT   = 0
  STATE_PUBLIC  = 1
  STATE_LOCKED  = 2
  STATE_ACTIVE  = 4
  STATE_OVER    = 8
  STATE_FAILED  = 16

	belongs_to :owner, class_name: 'User'
	has_many :users
	belongs_to :ruleset
	belongs_to :server
	belongs_to :game
end
