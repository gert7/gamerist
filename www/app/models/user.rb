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
#  created_at             :datetime
#  updated_at             :datetime
#

require 'agis'

class User < ActiveRecord::Base
  include Agis
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
         
  devise :omniauthable, omniauth_providers: [:steam]
  
  has_one :account, inverse_of: :user
  accepts_nested_attributes_for :account
  has_one :steamid, inverse_of: :user
  has_many :transactions, inverse_of: :user
  has_many :paypals, inverse_of: :user

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
  end
  
  def rapidkey(s)
    "gamerist-user {" + s + "}" + self.id.to_s
  end
  
  def hrapidkey
    "gamerist-user {}" + self.id.to_s
  end
  
  # Ask ActiveRecord for the user's most recent
  # transaction balance. Loads up both realized
  # and unrealized
  def load_balance
    l = Transaction.where(user_id: self.id).last
    @unrealized = (l != nil ? l.balance_u : 0)
    @realized = (l != nil ? l.balance_r : 0)
    $redis.hset hrapidkey, "balance_unrealized", @unrealized
    $redis.hset hrapidkey, "balance_realized", @realized
  end
  
  # Total balance exclusively of unrealized funds
  def balance_unrealized
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
  def balance_realized
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
  def total_balance
    balance_unrealized + balance_realized
  end
  
  # Reserve the User with an associated row in
  # some table.
  # @param [Integer] kind Transaction::KIND_ enum for this reserver
  # @param [Integer] id ID for the row in this reserver type's table
  def reserve! (kind, id)
    $redis.hset hrapidkey, "reservation", kind.to_s + ":" + id.to_s
  end
  
  # Check if the Room associated with the User is alive.
  # Queries the Room's is_alive?
  # @param [Array] res The reservation provided by User#reservation
  # @return whether or not the Room is alive and data loss has not occured
  def reservation_lives?
    res = self.reservation
    return true if (res and res[0].to_i == Transaction::KIND_ROOM.to_i and Room.new(id: res[1].to_i).is_alive?)
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
    $redis.hset hrapidkey, "reservation", Transaction::KIND_ROOM.to_s + ":" + room_id.to_s
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
  
  # Load up steam_name and steam_avatar_urls for the User. They themselves call this implicitly
  def fetch_steamapi
    $redis.hfetch hrapidkey, "steamapi" do
      raise NoSteamID unless self.steamid
      require 'open-uri'
      steamapik = $GAMERIST_API_KEYS["steam"]
      response = JSON.parse(open("http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=#{steamapik}&steamids=#{self.steamid.to_s}").read)
      player = response["response"]["players"][0]
      $redis.hset hrapidkey, "avatar_urls", (player["avatar"] + " " + player["avatarmedium"] + " " + player["avatarfull"])
      $redis.hset hrapidkey, "steamname", player["personaname"]
      "1"
    end
  end
  
  # Steam name of the current user
  def steam_name
    return "Hello" if Rails.env.test?
    begin
      fetch_steamapi
      return $redis.hget hrapidkey, "steamname"
    rescue NoSteamID
      return nil
    end
  end
  
  # Three avatar URLs for the given user, increasing in size,
  # separated by spaces
  def steam_avatar_urls
    return "http:// http:// http://" if Rails.env.test?
    begin
      fetch_steamapi
      return $redis.hget hrapidkey, "avatar_urls"
    rescue NoSteamID
      return nil
    end
  end
  
  after_initialize do
    agis_defm2(:areserve_room)
    agis_defm1(:aunreserve_from_room)
  end
end

