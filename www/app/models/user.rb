# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  relevantgames          :text
#

require 'agis'

class User < ActiveRecord::Base
  include Agis
  # Include default devise modules. Others available are:
  # :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  
  devise :confirmable if Rails.env.production? # TODO check email verification in Production mode
         
  devise :omniauthable, omniauth_providers: [:steam]
  
  has_one :account, inverse_of: :user
  accepts_nested_attributes_for :account
  has_one :steamid, inverse_of: :user
  has_many :transactions, inverse_of: :user
  has_many :paypals, inverse_of: :user
  has_many :payouts, inverse_of: :user
  has_one :permission_set, inverse_of: :user

  has_many :usertraces, inverse_of: :user
  
  PAYPAL_TIMEOUT = 30

  after_save do
    unless(self.account)
      Account.create do |a|
        a.user_id = self.id
      end
    end
  end

  class NoSteamID < Exception
  end
  
  def agis_id
    self.id
  end
  
  # Either the name of the user's Steam account
  # or the first four characters of their email
  # address
  def name
    steam_name or (self.email[0..3] + "...")
    # puts "SSSS" + self.confirmed?.to_s
  end
  
  def rapidkey(s)
    "gamerist-user {" + s + "}" + self.id.to_s
  end
  
  def hrapidkey
    "gamerist-user {}" + self.id.to_s
  end
  
  def hvar_get(s)
    $redis.hget hrapidkey, s
  end
  
  def hvar_set(s, v)
    $redis.hset hrapidkey, s, v
  end
  
  # Ask ActiveRecord for the user's most recent
  # transaction balance. Loads up both realized
  # and unrealized
  def load_balance
    l = Transaction.where(user_id: self.id).last
    @unrealized = (l != nil ? l.balance_u : 0)
    @realized = (l != nil ? l.balance_r : 0)
    hvar_set "balance_unrealized", @unrealized
    hvar_set "balance_realized", @realized
  end
  
  def crunch_transactions
    Transaction.new(user_id: self.id).agis_call($redis) if self.id
  end
  
  # Total balance exclusively of unrealized funds
  def balance_unrealized(crunch=true)
    crunch_transactions if crunch
    $redis.hfetch hrapidkey, "balance_unrealized" do
      load_balance
      @unrealized
    end.to_i
  end
  
  # Change the total unrealized balance in Redis
  def balance_unrealized= (v)
    $redis.hset hrapidkey, "balance_unrealized", v
  end
  
  # Total balance for realized funds
  def balance_realized(crunch=true)
    crunch_transactions if crunch
    $redis.hfetch hrapidkey, "balance_realized" do
      load_balance
      @realized
    end.to_i
  end
  
  # Change the total realized balance in Redis
  def balance_realized= (v)
    $redis.hset hrapidkey, "balance_realized", v
  end
  
  # Total balance of unrealized + realized
  # funds. Realized funds can do everything
  # unrealized funds can do.
  def total_balance(crunch=true)
    balance_unrealized(crunch) + balance_realized(crunch)
  end
  
  # Reserve the User with an associated row in
  # some table.
  # @param [Integer] kind Transaction::KIND_ enum for this reserver
  # @param [Integer] id ID for the row in this reserver type's table
  def reserve! (kind, id)
    hvar_set "reservation", kind.to_s + ":" + id.to_s
  end
  
  ##########
  # Paypal #
  ##########
  
  def areserve_paypal (paypal_id)
    res = self.reservation
    return false if (not reservation_is_paypal?(paypal_id) and reservation_lives?)
    # return true if reservation_is_paypal?(paypal_id)
    reserve! Transaction::KIND_PAYPAL, paypal_id
    hvar_set "reservation", Transaction::KIND_PAYPAL.to_s + ":" + paypal_id.to_s
    hvar_set "paypal_timeout", Time.now.to_i + PAYPAL_TIMEOUT
    return true
  end
  
  def reserve_paypal! (paypal_id)
    self.acall($redis, :areserve_paypal, paypal_id)
  end
  
  def reservation_is_paypal?(paypal_id)
    res = self.reservation
    (res and res[0].to_i == Transaction::KIND_PAYPAL.to_i and res[1].to_i == paypal_id.to_i and reservation_lives?)
  end
  
  def paypal_timed_out?
    timeout = hvar_get hrapidkey, "paypal_timeout"
    return false if (timeout and timeout.to_i > Time.now.to_i)
    true
  end
  
  def aunreserve_from_paypal(paypal_id)
    return false unless self.reservation_is_paypal?(paypal_id)
    $redis.hdel hrapidkey, "reservation"
    $redis.hdel hrapidkey, "paypal_timeout"
    true
  end
  
  def unreserve_from_paypal(paypal_id)
    self.acall($redis, :aunreserve_from_paypal, paypal_id)
  end
  
  ##########
  # Payout #
  ##########
  def areserve_payout (payout_id)
    res = self.reservation
    return false if (not reservation_is_payout?(payout_id) and reservation_lives?)
    # return true if reservation_is_paypal?(paypal_id)
    reserve! Transaction::RES_PAYOUT, payout_id
    hvar_set "reservation", Transaction::RES_PAYOUT.to_s + ":" + payout_id.to_s
    hvar_set "paypal_timeout", Time.now.to_i + PAYPAL_TIMEOUT
    return true
  end
  
  def reserve_payout! (payout_id)
    self.acall($redis, :areserve_payout, payout_id)
  end
  
  def reservation_is_payout?(payout_id)
    res = self.reservation
    (res and res[0].to_i == Transaction::RES_PAYOUT.to_i and res[1].to_i == payout_id.to_i and reservation_lives?)
  end
  
  def payout_timed_out?
    timeout = hvar_get "paypal_timeout"
    return false if (timeout and timeout.to_i > Time.now.to_i)
    true
  end
  
  def aunreserve_from_payout(payout_id)
    return false unless self.reservation_is_payout?(payout_id)
    $redis.hdel hrapidkey, "reservation"
    $redis.hdel hrapidkey, "paypal_timeout"
    true
  end
  
  def unreserve_from_payout(payout_id)
    self.acall($redis, :aunreserve_from_payout, payout_id)
  end
  
  # Check if the Room associated with the User is alive.
  # Queries the Room's is_alive?
  # @param [Array] res The reservation provided by User#reservation
  # @return whether or not the Room is alive and data loss has not occured
  def reservation_lives?
    res = self.reservation
    return true if (res and res[0].to_i == Transaction::KIND_ROOM.to_i and Room.new(id: res[1].to_i).is_alive?)
    return true if (res and res[0].to_i == Transaction::KIND_PAYPAL.to_i and not self.paypal_timed_out?)
    return true if (res and res[0].to_i == Transaction::RES_PAYOUT.to_i and not self.payout_timed_out?)
    return false
  end
  
  # Check if the reservation is a given Room
  # @param [Integer] room_id ID for the given Room
  # @return Whether or not the User is reserved right now by this Room
  def reservation_is_room? (room_id)
    res = self.reservation
    (res and res[0].to_i == Transaction::KIND_ROOM.to_i and res[1].to_i == room_id.to_i and reservation_lives?)
  end
  
  def areserve_room (room_id, ruleset)
    res = self.reservation
    return false if (not reservation_is_room?(room_id) and reservation_lives?)
    return true if reservation_is_room?(room_id)
    vself = User.find(self.id) # now we have to load the data from the database
      return false unless vself.steamid
      return false unless vself.total_balance >= ruleset["wager"].to_i
    hvar_set "reservation", Transaction::KIND_ROOM.to_s + ":" + room_id.to_s
    return true
  end
  
  # Reserve a new room if the User is not already
  # reserved and is valid for reservation
  # @param [Integer] room_id ID for the given room
  # @param [Hash] ruleset Room#srules for this given room
  # @return [Boolean] Whether or not the User is now reserved
  def reserve_room! (room_id, ruleset)
    self.acall($redis, :areserve_room, room_id, ruleset)
  end
  
  def aunreserve_from_room(room_id)
    return false unless self.reservation_is_room?(room_id)
    $redis.hdel hrapidkey, "reservation"
    true
  end
  
  # Unreserve user if the Room ID is correct
  # @param [Integer] room_id ID of the room to check
  # @return [Boolean] whether or not the User was successfully unreserved
  def unreserve_from_room(room_id)
    self.acall($redis, :aunreserve_from_room, room_id)
  end
  
  # Whether or not the User is currently reserved at all
  def is_reserved?
    ($redis.hget hrapidkey, "reservation") != nil
  end
  
  # Array containing 1) the Transaction::KIND_ enum for the current reserver
  # 2) the ID for the row in the current reserver's table
  def reservation
    return nil unless reserve = $redis.hget(hrapidkey, "reservation")
    reserve.split(":")
  end
  
  # Returns an ActiveRecord instance of Room, only if the current reservation is a Room
  def get_reservation
    reserve = $redis.hget hrapidkey, "reservation"
    if reserve
      resp = reserve.split(":")
      if(resp[0].to_i == Transaction::KIND_ROOM)
        return Room.find(resp[1].to_i)
      end
    end
  end
  
  def convert_id(id)
    return '765' + (id.to_i + 61197960265728).to_s
  end
  
  def load_steamplayer
    require 'open-uri'
    steamapik = GameristApiKeys.get("steam_api_key")
    ru = open("http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=#{steamapik}&steamids=#{self.steamid}").read
    response = JSON.parse(ru)
    return response["response"]["players"][0]
  end
  
  def load_steam_gamestats
    require 'open-uri'
    steamapik = GameristApiKeys.get("steam_api_key")
    ru = open("http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=#{steamapik}&steamid=#{self.steamid}&format=json").read
    response = JSON.parse(ru)
    return response["response"]
  end
  
  def save_game_stats(stats)
    if(stats["game_count"] == 0)
      return
    else
      tf2  = stats["games"].find do |x|
        x["appid"].to_i == 440
      end
      css  = stats["games"].find do |x|
        x["appid"].to_i == 240
      end
      if tf2
        hvar_set "GAME team fortress 2", tf2["playtime_forever"]
      else $redis.hdel hrapidkey, "GAME team fortress 2" end
      if css
        hvar_set "GAME counter strike source", css["playtime_forever"]
      else $redis.hdel hrapidkey, "GAME counter strike source" end
    end
  end
  
  # check if timed out
  # set next timeout in absolute POSIX time
  def steamapi_timeout(nextposix=nil)
    if nextposix
      hvar_set "steam_api_timeout", nextposix
    else
      if Time.now.to_i > hvar_get("steam_api_timeout").to_i
        return true
      else
        return false
      end
    end
  end
  
  # Load up steam_name and steam_avatar_urls for the User. They themselves call this implicitly
  def fetch_steamapi
    if (not hvar_get "avatar_urls" or
        not hvar_get "steamname" or
        not hvar_get "steamurl" or
        not hvar_get "owned_games" or
        steamapi_timeout)
      return nil unless self.steamid
      player = load_steamplayer
      return nil unless player
      hvar_set "avatar_urls", (player["avatar"] + " " + player["avatarmedium"] + " " + player["avatarfull"])
      hvar_set "steamname", player["personaname"]
      hvar_set "steamurl", player["profileurl"]
      save_game_stats(load_steam_gamestats)
      steamapi_timeout(Time.now)
    end
  end
  
  # Steam name of the current user
  def steam_name
    return "Hello" if Rails.env.test?
    fetch_steamapi
    return $redis.hget hrapidkey, "steamname"
  end
  
  # Three avatar URLs for the given user, increasing in size,
  # separated by spaces
  def steam_avatar_urls
    return "http:// http:// http://" if Rails.env.test?
    fetch_steamapi
    return $redis.hget hrapidkey, "avatar_urls"
  end
  
  def steam_profile_url
    return "http://" if Rails.env.test?
    fetch_steamapi
    return $redis.hget hrapidkey, "steamurl"
  end
  
  def has_game(gamename)
    return hvar_get("GAME " + gamename)
  end
  
  after_initialize do
    agis_defm2(:areserve_room)
    agis_defm1(:aunreserve_from_room)
    agis_defm1(:areserve_paypal)
    agis_defm1(:aunreserve_from_paypal)
    agis_defm1(:areserve_payout)
    agis_defm1(:aunreserve_from_payout)
  end
end

