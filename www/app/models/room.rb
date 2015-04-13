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
  
  WAGER_MIN = 5
  WAGER_MAX = 50
  
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
  validates :wager, inclusion: {in: (WAGER_MIN-1)...(WAGER_MAX+1), message: "Wager of invalid size!!!"}
  validates :server, inclusion: {in: [nil, ""].concat($gamerist_serverdata["servers"].map {|g| g["name"]}), message: "Server is not valid!!!"}
  # validates :server
  
  before_validation  do
    self.state ||= STATE_PUBLIC
    self.server ||= $gamerist_serverdata["servers"][0]["name"]
    @playercount = playercount.to_i
    @wager = wager.to_i.floor
  end
  
  before_save do
    self.rules ||= JSON.generate({game: @game, map: @map, playercount: @playercount, wager: @wager, server: @server, players: []})
  end

  def rapidkey(s)
    "gamerist-room" + s + "-#{id}"
  end
  
  def srules
    a = $redis.fetch(rapidkey "rules") do
      self.rules
    end
    JSON.parse(a)
  end
  
  def srules=(a)
    self.rules = JSON.generate(a)
    $redis.set rapidkey("rules"), self.rules
  end
  
  def rstate
    $redis.fetch(rapidkey "state") do
      self.state
    end.to_i
  end
  
  def rstate=(a)
    self.state = a
    $redis.set rapidkey("state"), self.state
  end
  
  def check_ready(ruleset)
    if(ruleset["players"].count == ruleset["playercount"] and
       self.rstate == STATE_PUBLIC and
       ruleset["players"].inject(true) {|acc, v| acc and v["ready"].to_i == 1})
      self.rstate = STATE_LOCKED
      self.save!
    end
  end
  
  # append players live
  def append_player!(player)
    $redis.lock(rapidkey("rules"), life: 5) do
      mrules = self.srules
      if(self.rstate == STATE_PUBLIC and
         mrules["players"].count < mrules["playercount"] and
         not player.is_reserved? and
         player.total_balance >= srules["wager"])
        mrules["players"].push({id: player.id, ready: 0, wager: srules["wager"]})
        $redis.multi do
          player.reserve! Transaction::KIND_ROOM, self.id
          self.srules = mrules
        end
        return true
      end
      return false
    end
  end
  
  # remove players live
  def remove_player!(player)
    mrules = self.srules # read shared data /
    pi = mrules["players"].find_index { |v| v["id"].to_i == player.id }
    if(pi and
       self.rstate == STATE_PUBLIC)
      mrules["players"].delete_at(pi)
      $redis.multi do
        player.unreserve!
        self.srules = mrules # / write shared data
      end
      return true
    end
    return false
  end
  
  # amend players live
  def amend_player!(player, hash)
    mrules = srules # read shared data /
    pi = mrules["players"].find_index { |v| v["id"].to_i == player.id }
    if(pi and
       (hash["wager"] ? (hash["wager"] > WAGER_MIN and hash["wager"] < WAGER_MAX) : true))
      mrules["players"][pi] = mrules["players"][pi].merge(hash)
      check_ready(mrules)
      self.srules = mrules # / write shared data
      return true
    end
    return false
  end
end

