# == Schema Information
#
# Table name: rooms
#
#  id         :integer          not null, primary key
#  state      :integer
#  created_at :datetime
#  updated_at :datetime
#  rules      :text
#

class Room < ActiveRecord::Base
  attr_accessor :game, :map, :playercount, :wager, :spreadmode, :spread, :server
  
  STATE_DRAFT   = 0  # draft --unused
  STATE_PUBLIC  = 1  # waiting for players in browser
  STATE_LOCKED  = 2  # everybody is ready, waiting for server
  STATE_ACTIVE  = 4  # game is being played
  STATE_OVER    = 8  # game is done
  STATE_FAILED  = 16 # game has failed for whatever reason

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
  
  def map_in_maplist()
    if(ml = $gamerist_mapdata["games"].find {|g| g["name"] == @game})
      unless (ml["maps"].map {|m| m["name"]}.include? @map)
        errors.add(:map, "Map is invalid!!!")
      end
    end
  end

  validates :game, inclusion: {in: $gamerist_mapdata["games"].map {|g| g["name"]}, message: "Game is not valid!!!"}
  validate :map_in_maplist
  validates :playercount, inclusion: {in: [4, 8, 16, 32], message: "Playercount is not valid!!!"}
  validates :wager, inclusion: {in: 4...51, message: "Wager of invalid size!!!"}
  # validates :server
  
  before_validation  do
    self.state = @state || STATE_PUBLIC
    @playercount = playercount.to_i
    @wager = wager.to_i.floor
  end
  
  before_save do
    puts JSON.generate({game: @game, map: @map, playercount: @playercount, wager: @wager})
    self.rules = @rules || JSON.generate({game: @game, map: @map, playercount: @playercount, wager: @wager})
  end
  
  after_save do
    Rails.cache.write("#{cache_key}/standing", JSON.generate({}))
  end
  
  def srules
    JSON.parse(self.rules)
  end
end

