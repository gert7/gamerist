# Game identity, i.e. TF2, CS, Warsow
class Game < ActiveRecord::Base
	has_many :rooms
	has_many :maps
end
