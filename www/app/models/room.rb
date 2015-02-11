# == Schema Information
#
# Table name: rooms
#
#  id         :integer          not null, primary key
#  state      :integer
#  created_at :datetime
#  updated_at :datetime
#  rules      :string(255)
#

class Room < ActiveRecord::Base
  attr_accessor :game, :map, :timelimit, :playercount, :wager, :spreadmode, :spread
  
  STATE_DRAFT   = 0
  STATE_PUBLIC  = 1
  STATE_LOCKED  = 2
  STATE_ACTIVE  = 4
  STATE_OVER    = 8
  STATE_FAILED  = 16

  SPREAD_VERTICAL = 1 # best team wins
  SPREAD_HORIZONTAL = 2 # best 50% wins

  PLAYERS_FOUR = 4
  PLAYERS_EIGHT = 8
  PLAYERS_SIXTEEN = 16
  PLAYERS_THIRTYTWO = 32

  ODDS_HALF = 2 # best 50% win, min 2 players
  ODDS_QUARTER = 4 # best 25% win, min 4 players
  ODDS_EIGHTH = 8 # best 1/8 win, min 8 players
  ODDS_SIXTEENTH = 16 # best 1/16 win, min 16 players
  ODDS_SINGLE = 32 # best 1/32 (up to 1 player) wins, min 32 players
  
	has_many :users, inverse_of: :rooms

  validates :state, presence: true
  validates :rules, presence: true

  def make_room()
  end
end
