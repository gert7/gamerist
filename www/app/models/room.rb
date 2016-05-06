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
require Rails.root.join("app", "models", "concerns", "room_transformations")
require Rails.root.join("app", "models", "concerns", "room_utilities")
require Rails.root.join("app", "models", "concerns", "roomlist")

class Room < ActiveRecord::Base
  attr_accessor :game, :map, :playercount, :wager, :spreadmode, :spread, :server, :server_region, :personal_messages
  include Agis
  include RoomTransformations
  include RoomUtilities
  
  TIMEOUT_ROOMLIST = 8
  TIMEOUT_PUBLIC   = 240
  
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
  
  WAGER_MIN = Modifier.get("ROOM_WAGER_MIN").to_i
  WAGER_MAX = Modifier.get("ROOM_WAGER_MAX").to_i
  
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
  
  def server_available_for_continent()
    Room.continent_exists?(@server_region)
  end
  
  def ctf_playerlimit
    unless @map
      errors.add(:playercount, "No map!") 
      return
    end
    if(@map[0..3] == "ctf_")
      errors.add(:playercount, "Playercount too high for CTF!") if @playercount > 16
    end
  end

  validates :game, inclusion: {in: $gamerist_mapdata["games"].map {|g| g["name"]}, message: "Game is not valid!!!"}, on: :create
  validate :map_in_maplist, on: :create
  if(Rails.env.test? or Rails.env.development?)
    validates :playercount, inclusion: {in: [1, 4, 8, 16, 24, 32], message: "Playercount is not valid!!!111"}, on: :create
  else
    validates :playercount, inclusion: {in: [8, 16, 24, 32], message: "Playercount is not valid!!!"}, on: :create
  end
  validate :ctf_playerlimit, on: :create
  validates :wager, inclusion: {in: (WAGER_MIN-1)...(WAGER_MAX+1), message: "Wager of invalid size!!!"}, on: :create
  #validates :server, inclusion: {in: [nil, ""].concat($gamerist_serverdata["servers"].map {|g| g["name"]}), message: "Server is not valid!!!"}
  #validate :server_in_serverlist
  validate :server_available_for_continent, on: :create
  
  before_validation do
    self.state  ||= STATE_PUBLIC
    self.server ||= $gamerist_serverdata["servers"][0]["name"]
    @playercount = playercount.to_i
    @wager = wager.to_i.floor
  end
  
  before_save do
    self.rules ||= JSON.generate({server_region: @server_region, game: @game, map: @map, playercount: @playercount, wager: @wager, players: []})
  end
  
  after_save do
    if self.game # is this a new save?
      $redis.hset rapidkey, "rules", self.rules
      $redis.hset rapidkey, "state", self.state
      $redis.hset rapidkey, "is_alive", "true"
      RoomList.roomlist_add(self)
      self.room_renew_timeout
    end
  end
  
  # Check if a specific continent has a working server
  def self.continent_exists?(continent)
    if($gamerist_serverdata["servers"].find_index do |s|
      s["region"] == continent and (s["production"] == true or (not Rails.env.production?))
    end)
      return true
    end
    false
  end
  
  def rapidkey
    "gamerist-room {" + self.id.to_s + "}"
  end
  
  def room_renew_timeout(specific=nil)
    if (not room_timed_out? and (Room::STATE_PUBLIC or Room::STATE_LOCKED))
      $redis.hset(rapidkey, "timeout", (specific or (Time.now.to_i + Room::TIMEOUT_PUBLIC)))
    end
  end

  def expire_room!
    self.rstate = Room::STATE_FAILED
    self.save
    $redis.del(rapidkey)
  end

  # Actively modifies the Room to become FAILED if 
  # the Room has timed out
  def room_timed_out?
    to = $redis.hget(rapidkey, "timeout")
    # dump_timeout_players
    if to
      if (to.to_i < Time.now.to_i) and (self.srules["players"].count == 0 or self.rstate == Room::STATE_LOCKED)
        Room.find(self.id).expire_room!
        return true
      end
    end
    false
  end
  
  # Check if the is_alive key is set for this room in Redis
  def is_alive?
    return true if Rails.env.development?
    if $redis.hget(rapidkey, "is_alive") == "true" and
       ((self.rstate != Room::STATE_PUBLIC) or (not room_timed_out?))
      return true
    else
      dself  = Room.find(self.id)
      mrules = dself.srules
      mrules["errors"] ||= []
      mrules["errors"] << "web_timeout"
      dself.srules = mrules
      dself.expire_room! # and save
      return false
    end
  end
  
  # @return hash containing the ruleset for this room, includes all central data except state (see rstate)
  def srules
    a = $redis.hfetch(rapidkey, "rules") do
      self.rules
    end
    JSON.parse(a)
  end
  
  # @return hash containing the ruleset for this room, without going through Redis cache
  def crules
    JSON.parse(self.rules)
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
  
  def update_relevant_users(mrules)
    users = User.find(mrules["players"].map{|p| p["id"]})
    users.each do |v|
      v.relevantgames = (v.relevantgames or "") + self.id.to_s + ";"
      v.save!
    end
  end
  
  # Locks the room and saves it in ActiveRecord
  # if 1) the room is full 2) everyone is ready.
  # This method may write to ActiveRecord
  def lock_if_ready(ruleset)
    if((self.total_players(ruleset) == ruleset["playercount"]) and
       (self.is_public?) and
       (ruleset["players"].inject(true) {|acc, v| acc and (v["ready"].to_i == 1 or v["team"].to_s == "0")}))
      ruleset      = remove_exo_players(ruleset)
      self.rules  = JSON.generate(ruleset)
      self.rstate = STATE_LOCKED
      self.save
      update_relevant_users(ruleset)
    end
    ruleset
  end
  
  # Calls dump_timeout_players, check_wager and
  # lock_if_ready in sequence.
  # @param [Hash] ruleset old version of srules
  # @return [Hash] new version of srules
  def check_ready(ruleset)
    (lock_if_ready (check_wager (dump_timeout_players ruleset)))
  end
  
  # Adds the player by ID to the given srules
  # @param [Hash] mrules old version of srules
  # @param [Integer] player_id ID of player to add
  # @return [Hash] new version of srules
  def append_player_hash(mrules, player_id)
    player = User.find(player_id)
    return mrules if fetch_player(player_id, mrules)
    mrules["players"].push({"id" => player_id, "ready" => 0, "wager" => mrules["wager"], "avatar" => player.steam_avatar_urls.split(" ")[0], "steamname" => player.steam_name, "steamid" => player.steamid.steamid2, "team" => 0, "steamurl" => player.steam_profile_url})
    mrules
  end
  
  def amend_player_wager(mrules, player, pi, hash)
    if(hash["wager"])
      if(hash["wager"].to_i >= WAGER_MIN and
       hash["wager"].to_i <= WAGER_MAX and
       player.total_balance >= hash["wager"].to_i)
         mrules["players"][pi]["wager"] = hash["wager"]
      else
        self.personal_messages << [2, "Wager is not valid!"]
      end
    end
    mrules
  end
  
  # Modifies a player's hash in a ruleset
  # @param [Hash] mrules old version of srules
  # @param [User] player ActiveModel instance of the given player
  # @param [Hash] hash the given modifications to the user
  # @return [Hash] new version of srules
  def amend_player_hash(mrules, player, hash)
    return mrules unless ((hash["team"] and hash["team"].to_s != "0") or fetch_player(player.id, mrules))
    mrules = append_player_hash(mrules, player.id)
    pi     = fetch_player(player.id, mrules)
    mrules = append_ip_address(pi, mrules, hash)
    mrules = assign_to_team(pi, mrules, hash)             if hash["team"]
    mrules = amend_player_wager(mrules, player, pi, hash) if hash["wager"]
    mrules = amend_player_ready(mrules, pi, hash)         if hash["ready"]
    mrules["players"][pi]["timeout"] = Time.now.to_i + ROOM_TIMEOUT
    mrules
  end
  
  def aamend_player(player_id, hash)
    self.personal_messages ||= []
    mrules = self.srules
    player = User.new(id: player_id)
    if hash["team"] and hash["team"].to_i != 0
      return false unless (self.total_players(mrules) < mrules["playercount"])
      unless player.has_game(mrules["game"])
        self.personal_messages << [3, "You do not seem to own this game!"]
        return false
      end
      unless (player.reserve_room!(self.id, mrules))
        self.srules = _remove_player!(player_id, mrules)
        return false
      end
      hash["timeout"] = (Time.now + ROOM_TIMEOUT).to_i
    end
    mrules = check_ready(amend_player_hash(mrules, player, hash))
    self.srules = mrules
    true
  end
  
  def aremove_player(player_id)
    p = User.new(id: player_id)
    self.srules = _remove_player!(player_id, removenoticemsg(srules, player_id))
    return true unless p.reservation_is_room?(self.id)
    User.new(id: player_id).unreserve_from_room(self.id)
  end
  
  def prejoindata(user, region)
    result = ""
    #puts region
    #puts self.srules["server_region"]
    result += "NW" if(user.total_balance < self.srules["wager"])
    result += "NR" if(region != self.srules["server_region"])
    (result == "") ? "Y" : result
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
  
  def aappend_chatmessage(player_id, steamname, msg)
    mrules = srules
    mrules = chat_addmsg(mrules, player_id, steamname, msg)
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
    self.acall($redis, :aappend_chatmessage, player.id, player.steam_name, message)
  end
  
  def aadd_running_server(server)
    cr = $redis.hget(rapidkey, "search_result")
    c = JSON.parse(cr) if cr
    c ||= {"servers" => []}
    c["servers"] << server
    $redis.hset rapidkey, "search_result", JSON.generate(c)
  end
  
  def add_running_server(server)
    self.acall($redis, :aadd_running_server, server)
  end
  
  def affirm_finalserver?
    finalserver = $redis.hget rapidkey, "final_server_address"
    if finalserver
      self.rstate = STATE_ACTIVE
      self.save!
      return true
    end
    false
  end
  
  def achug_room
    self.room_renew_timeout
    return if room_timed_out?
    return if affirm_finalserver?
    state       = $redis.hget rapidkey, "search_searching"
    tout        = $redis.hget rapidkey, "search_timeout"
    results     = $redis.hget rapidkey, "search_result"
    if state == nil or (state == "yes" and not results and tout.to_i < Time.now.to_i)
      DispatchMQ.send_room_requests(self)
      $redis.hset rapidkey, "search_searching", "yes"
      $redis.hset rapidkey, "search_timeout", Time.now.to_i + 25 # TODO make sure this is a good timeout - other half of mq.rb
    elsif ((state == "yes") and results and tout.to_i < Time.now.to_i)
      res = JSON.parse(results)["servers"] # servername, ip, port
      res[1..-1].each do |v|
        DispatchMQ.send_room_cancel(self.id, v["servername"])
      end
      $redis.hset rapidkey, "final_server_address", res[0]["ip"] + ":" + res[0]["port"].to_s
    end
  end
  
  def chug_room
    self.acall($redis, :achug_room)
  end
  
  def adeclare_winning_team(team)
    if self.rstate == STATE_ACTIVE and self.is_alive?
      mrules                = self.srules
      mrules["winningteam"] = team
      mrules["players"].each do |v|
        if v["team"].to_s == team.to_s
          Transaction.make_transaction(user_id: v["id"], amount: mrules["wager"].to_i, state: Transaction::STATE_FINAL, kind: Transaction::KIND_ROOM, detail: self.id)
        else
          Transaction.make_transaction(user_id: v["id"], amount: (0 - mrules["wager"].to_i), state: Transaction::STATE_FINAL, kind: Transaction::KIND_ROOM, detail: self.id)
        end
        User.new(id: v["id"]).unreserve_from_room(self.id)
      end
      self.srules = mrules
      self.rstate = STATE_OVER
      self.save
      $redis.del(rapidkey)
    end
  end
  
  def declare_winning_team(team)
    self.acall($redis, :adeclare_winning_team, team)
  end
  
  def adeclare_team_scores(tscores)
    mrules = self.srules
    tscores.each do |tv|
      pi = mrules["players"].find_index {|pv| pv["steamid"] == tv["steamid"]}
      mrules["players"][pi]["score"] = tv["score"]
    end
    self.srules = mrules
    self.save
  end
  
  def declare_team_scores(tscores)
    self.acall($redis, :adeclare_team_scores, tscores)
  end
  
  def adeclare_error(err)
    mrules = self.srules
    mrules["errors"] ||= []
    mrules["errors"] << err
    self.srules = mrules
    self.save(validate: false)
  end
  
  def declare_error(err)
    self.acall($redis, :adeclare_error, err)
  end
  
  def final_server_address
    $redis.hget rapidkey, "final_server_address"
  end
  
  def sanitized_srules(user)
    if (self.rstate >= STATE_LOCKED and fetch_player(user.id, self.srules) == nil)
      return nil
    end
    mrules = self.srules
    mrules["players"].each_index do |pi|
      mrules["players"][pi].delete("known_ips")
    end
    mrules
  end
  
  # XHR direct line to amending a player.
  # params upclass: readywager (default) or chatroom
  # @param [User] cuser ActiveRecord instance of the player
  # @param [Hash] params parameters sent through controller PATCH method
  def update_xhr(cuser, params, region=nil)
    return if room_timed_out?
    return unless self.is_alive?
    region ||= self.srules["server_region"]
    if params["upclass"] == "chatroom" and self.is_public?
      append_chatmessage!(cuser, params["message"]) unless params["message"].gsub(/\s+/, "") == ""
    elsif params["upclass"] == "generic"
      chug_room if self.rstate == STATE_LOCKED
    elsif self.is_public? and region == self.srules["server_region"] # readywager
      if(params["wager"] and params["wager"].to_s == "0")
        remove_player!(cuser)
      else
        amend_player!(cuser, params)
      end
    end
    room_renew_timeout if self.srules["players"].count > 0
  end
  
  after_initialize do
    agis_defm1(:aremove_player)
    agis_defm2(:aamend_player)
    agis_defm3(:aappend_chatmessage)
    agis_defm0(:achug_room)
    agis_defm1(:aadd_running_server)
    agis_defm1(:adeclare_winning_team)
    agis_defm1(:adeclare_team_scores)
  end
end

