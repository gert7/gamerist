class Room < ActiveRecord::Base
  STATE_DRAFT   = 0
  STATE_PUBLIC  = 1
  STATE_LOCKED  = 2
  STATE_ACTIVE  = 4
  STATE_OVER    = 8
  STATE_FAILED  = 16

	belongs_to :owner, class_name: 'User', inverse_of: :rooms_owned
	has_many :users, inverse_of: :rooms
	belongs_to :ruleset, inverse_of: :rooms
	belongs_to :server, inverse_of: :rooms
	belongs_to :game, inverse_of: :rooms
end
