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

# Ruleset structure:
#
# game
# map
# playercount
# wager
# server
# players[]:
#   id
#   ready
#   wager
#   avatar
#   steamid
#   timeout
# messages[]:
#   index
#   message
#   userid
#   addendum

require 'agis'

class Room < ActiveRecord::Base
  attr_accessor :game, :map, :playercount, :wager, :spreadmode, :spread, :server
  include Agis
  
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
  
  MESSAGES_STORE_MAX = 40
  
  Rails.env.test? ? ROOM_TIMEOUT = 30.minutes : ROOM_TIMEOUT = 30.seconds
  
  has_many :users, inverse_of: :rooms
  
  def map_in_maplist()
    if(ml = $gamerist_mapdata["games"].find {|g| g["name"] == @game})
      unless (ml["maps"].map {|m| m["name"]}.include? @map)
        errors.add(:map, "Map is invalid!!!")
      end
    end
  end
  
  def server_in_serverlist()
    errors.add(:server, "Server is invalid!!!") unless($gamerist_serverdata["servers"].find {|s| (s["name"] == @server) and (s["production"] == true or (not Rails.env.production?)) })
  end

  validates :game, inclusion: {in: $gamerist_mapdata["games"].map {|g| g["name"]}, message: "Game is not valid!!!"}
  validate :map_in_maplist
  if(Rails.env.test? or Rails.env.development?)
    validates :playercount, inclusion: {in: [4, 8, 16, 24, 32], message: "Playercount is not valid!!!"}
  else
    validates :playercount, inclusion: {in: [8, 16, 24, 32], message: "Playercount is not valid!!!"}
  end
  validates :wager, inclusion: {in: (WAGER_MIN-1)...(WAGER_MAX+1), message: "Wager of invalid size!!!"}
  #validates :server, inclusion: {in: [nil, ""].concat($gamerist_serverdata["servers"].map {|g| g["name"]}), message: "Server is not valid!!!"}
  validate :server_in_serverlist
  
  before_validation do
    self.state  ||= STATE_PUBLIC
    self.server ||= $gamerist_serverdata["servers"][0]["name"]
    @playercount = playercount.to_i
    @wager = wager.to_i.floor
  end
  
  before_save do
    self.rules ||= JSON.generate({game: @game, map: @map, playercount: @playercount, wager: @wager, server: @server, players: []})
  end
  
  after_save do
    $redis.hset rapidkey, "is_alive", "true"
  end
  
  def rapidkey
    "gamerist-room {" + self.id.to_s + "}"
  end
  
  # Check if the is_alive key is set for this room in Redis
  def is_alive?
    return true if Rails.env.development?
    return true if $redis.hget(rapidkey, "is_alive") == "true"
    false
  end
  
  # @return hash containing the ruleset for this room, includes all central data except state (see rstate)
  def srules
    a = $redis.hfetch(rapidkey, "rules") do
      self.rules
    end
    JSON.parse(a)
  end
  
  # @param [Hash] a hash of rules that will be converted into JSON object
  def srules=(a)
    self.rules = JSON.generate(a)
    $redis.hset rapidkey, "rules", self.rules
  end
  
  # STATE_DRAFT   = 0  draft --unused
  # STATE_PUBLIC  = 1  waiting for players in browser
  # STATE_LOCKED  = 2  everybody is ready, waiting for server
  # STATE_ACTIVE  = 4  game is being played
  # STATE_OVER    = 8  game is done
  # STATE_FAILED  = 16 game has failed for whatever reason
  # @return [Integer] number enum of room state
  def rstate
    $redis.hfetch rapidkey, "state" do
      self.state
    end.to_i
  end
  
  # @param [Integer] a specify a new enum of room state
  def rstate=(a)
    self.state = a
    $redis.hset rapidkey, "state", self.state
  end
  
  # @return [Boolean] whether or not the room state is 1 (STATE_PUBLIC)
  def is_public?
    self.rstate == STATE_PUBLIC
  end
  
  # Find the players array index of a player in the given ruleset
  # @param [Integer] pid the id of the User of this player
  # @param [Hash] mrules a version of srules
  # @return [Integer] The position of the player in the given ruleset's player list
  def fetch_player(pid, mrules)
    mrules["players"].find_index { |v| v["id"].to_i == pid }
  end
  
  # Remove all players who are over their timeout
  # @param [Hash] mrules old version of srules
  # @return [Hash] new version of srules
  def dump_timeout_players(mrules)
    mrules["players"].each_with_index do |p, ind|
      if (p["team"].to_s != "0" and
          ((p["timeout"].to_i < Time.now.to_i) or
          not User.new(id: p["id"]).reservation_is_room?(self.id)))
        mrules["players"].delete_at(ind)
      end
    end
    mrules
  end
  
  # Sets the new wager for mrules.
  # If the lowest common wager for the room is
  # greater than the current, it shall be the new
  # shared wager.
  # If the highest common wager for the room is
  # lower than the current, it shall be the new
  # shared wager.
  #
  # @param [Hash] mrules old version of srules
  # @return [Hash] new version of srules
  def check_wager(mrules)
    wagers = mrules["players"].select{|v| v["team"].to_s != "0" and v["wager"].to_i > 0}.map {|v| v["wager"].to_i}
    min, max = wagers.min, wagers.max
    if(min and (min > mrules["wager"].to_i))
      mrules["wager"] = min
    elsif(max and (max < mrules["wager"].to_i))
      mrules["wager"] = max
    end
    mrules
  end
  
  # Removes all players not in teams
  def remove_exo_players(mrules)
    mrules["players"].delete_if {|value| value["team"].to_s == "0"}
    return mrules
  end
  
  # Locks the room and saves it in ActiveRecord
  # if 1) the room is full 2) everyone is ready.
  # This method may write to ActiveRecord
  def lock_if_ready(ruleset)
    if((self.total_players(ruleset) == ruleset["playercount"]) and
       (self.is_public?) and
       (ruleset["players"].inject(true) {|acc, v| acc and (v["ready"].to_i == 1 or v["team"].to_s == "0")}))
      ruleset     = remove_exo_players(ruleset)
      self.rstate = STATE_LOCKED
      self.save!
    end
    ruleset
  end
  
  # Calls dump_timeout_players, check_wager and
  # lock_if_ready in sequence.
  #
  # @param [Hash] ruleset old version of srules
  # @return [Hash] new version of srules
  def check_ready(ruleset)
    (lock_if_ready (check_wager (dump_timeout_players ruleset)))
  end
  
  # Removes the player from the given mrules if the room is public
  # @param [Integer] player_id ID of the given player's User
  # @param [Hash] mrules old version of srules
  # @return new version of srules
  def _remove_player!(player_id, mrules)
    pi = fetch_player(player_id, mrules)
    if(pi and
       self.is_public?)
      mrules["players"].delete_at(pi)
    end
    mrules
  end
  
  # Adds the player by ID to the given srules
  # @param [Hash] mrules old version of srules
  # @param [Integer] player_id ID of player to add
  # @return [Hash] new version of srules
  def append_player_hash(mrules, player_id)
    player = User.find(player_id)
    return mrules if fetch_player(player_id, mrules)
    mrules["players"].push({"id" => player_id, "ready" => 0, "wager" => mrules["wager"], "avatar" => player.steam_avatar_urls.split(" ")[0], "steamname" => player.steam_name, "steamid" => player.steamid.steamid, "team" => 0})
    mrules
  end
  
  def teamcounts(mrules)
    teams = [0, 0]
    mrules["players"].each do |v|
      if(v["team"] == 2)
        teams[0] += 1
      elsif(v["team"] == 3)
        teams[1] += 1
      end
    end
    return teams
  end
  
  def total_players(mrules)
    teams = self.teamcounts(mrules)
    return teams[0] + teams[1]
  end
  
  def assign_to_team(pi, mrules, hash)
    return mrules unless hash["team"]
    mrules["players"][pi]["team"] = 0 if (hash["team"].to_s == "0")
    return mrules if hash["team"].to_s == "0"
    piteam = mrules["players"][pi]["team"]
    return mrules if piteam == hash["team"]
    tcount  = self.teamcounts(mrules)
    perteam = mrules["playercount"] / 2
    if hash["team"]
      if(hash["team"].to_i == 2 and tcount[0] < perteam)
        mrules["players"][pi]["team"] = 2
      elsif(hash["team"].to_i == 3 and tcount[1] < perteam)
        mrules["players"][pi]["team"] = 3
      else
        mrules["players"][pi]["team"] = 0
      end
    #else
    #  if(tcount[0] > tcount[1])
    #    give = 3
    #  else
    #    give = 2 # by default, move to red
    #  end
    end
    mrules["players"][pi]["wager"] = mrules["wager"]
    return mrules
  end
  
  def amend_player_wager(mrules, player, pi, hash)
    if(hash["wager"] and 
       hash["wager"].to_i >= WAGER_MIN and
       hash["wager"].to_i <= WAGER_MAX and
       player.total_balance >= hash["wager"].to_i)
      mrules["players"][pi]["wager"] = hash["wager"]
    end
    mrules
  end
  
  def amend_player_ready(mrules, pi, hash)    
    mrules["players"][pi]["ready"] = hash["ready"] if(hash["ready"])
    mrules
  end
  
  # Modifies a player's hash in a ruleset
  # @param [Hash] mrules old version of srules
  # @param [User] player ActiveModel instance of the given player
  # @param [Hash] hash the given modifications to the user
  # @return [Hash] new version of srules
  def amend_player_hash(mrules, player, hash)
    mrules = append_player_hash(mrules, player.id)
    pi     = fetch_player(player.id, mrules)
    mrules = assign_to_team(pi, mrules, hash)             if hash["team"]
    mrules = amend_player_wager(mrules, player, pi, hash) if hash["wager"]
    mrules = amend_player_ready(mrules, pi, hash)         if hash["ready"]
    mrules["players"][pi]["timeout"] = Time.now.to_i + ROOM_TIMEOUT
    mrules
  end
  
  def aamend_player(player_id, hash)
    mrules = self.srules
    player = User.new(id: player_id)
    return false unless (self.is_public?)
    if hash["team"] and hash["team"].to_i != 0
      return false unless (self.total_players(mrules) < mrules["playercount"])
      unless (player.reserve_room!(self.id, mrules))
        self.srules = _remove_player!(player_id, mrules)
        return false
      end
      hash["timeout"] = (Time.now + ROOM_TIMEOUT).to_i
    end
    self.srules = check_ready(amend_player_hash(mrules, player, hash))
    true
  end
  
  # Add a remove notice to the given srules' chatbox
  # @param [Hash] mrules old version of mrules
  # @param [Integer] player_id the given player's User's id
  # @return [Hash] new version of srules
  def removenoticemsg(mrules, player_id)
    pi = fetch_player(player_id, mrules)
    return mrules unless pi
    add = "left:" + mrules["players"][pi]["steamname"] + " has left the room"
    mrules["messages"] ||= []
    if(mrules["messages"].count == 0)
      mrules["messages"] << {"message" => "TOP", "user_id" => 0, "addendum" => [add]}
    else
      mrules["messages"].last["addendum"] << add
    end
    mrules
  end
  
  def aremove_player(player_id)
    p = User.new(id: player_id)
    self.srules = _remove_player!(player_id, removenoticemsg(srules, player_id))
    return true unless p.reservation_is_room?(self.id)
    User.new(id: player_id).unreserve_from_room(self.id)
  end
  
  def prejoindata(user)
    if(user.total_balance < self.srules["wager"])
      return "NW"
    else
      return "Y"
    end
  end
  
  # Amend the given player's standing in the Room's ruleset
  # 
  # This method writes to Redis and possibly to ActiveRecord
  # @param [User] player ActiveRecord instance of the player
  # @param [Hash] hash set of changes to user in Room
  def amend_player!(player, hash)
    self.acall($redis, :aamend_player, player.id, (hash or {}))
  end
  
  # Remove the given player from the Room's ruleset
  # Doesn't care if the player is already removed
  #
  # This method writes to Redis
  # @param [User] player ActiveRecord instance of the player
  def remove_player!(player)
    self.acall($redis, :aremove_player, player.id)
  end
  
  # Add the player to the Room's ruleset.
  # Amend player does the same thing, use that instead
  # @param [User] player ActiveRecord instance of the player
  def append_player!(player)
    self.acall($redis, :aamend_player, player.id, {})
  end
  
  def aappend_chatmessage(player_id, msg)
    mrules = srules
    mrules["messages"] ||= []
    ind = mrules["messages"].last["index"] if mrules["messages"].last
    ind ||= 0
    mrules["messages"] << {"index" => ind + 1, "message" => msg, "user_id" => player_id, "addendum" => []}
    mrules["messages"] = mrules["messages"][1..-1] if(mrules["messages"].count > Room::MESSAGES_STORE_MAX)
    self.srules = mrules
  end
  
  # Append a chat message associated with a user
  # to the Room's chatbox. Each message contains an
  # unrelated addendum array for messages about
  # players entering or leaving the room.
  # The chatroom only persists the last 40 messages
  # @param [User] player ActiveRecord instance of the player
  # @param [String] message string of the user's message
  def append_chatmessage!(player, message)
    self.acall($redis, :aappend_chatmessage, player.id, message)
  end
  
  # XHR direct line to amending a player.
  # params upclass: readywager (default) or chatroom
  # @param [User] cuser ActiveRecord instance of the player
  # @param [Hash] params parameters sent through controller PATCH method
  def update_xhr(cuser, params)
    if params["upclass"] == "chatroom"
      append_chatmessage!(cuser, params["message"]) unless params["message"].gsub(/\s+/, "") == ""
    elsif params["upclass"] == "generic"
      a = 0
    else # readywager
      if(params["wager"] and params["wager"].to_s == "0")
        remove_player!(cuser)
      else
        amend_player!(cuser, params)
      end
    end
  end
  
  after_initialize do
    agis_defm1(:aremove_player)
    agis_defm2(:aamend_player)
    agis_defm2(:aappend_chatmessage)
  end
end

