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

class User < ActiveRecord::Base
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
  
  def name
    steam_name or (self.email[0..3] + "...")
  end
  
  def rapidkey(s)
    "gamerist-user {" + s + "}" + self.id.to_s
  end
  
  def hrapidkey
    "gamerist-user {}" + self.id.to_s
  end
  
  # unrealized + realized
  def load_balance
    l = Transaction.where(user_id: self.id).last
    @unrealized = (l != nil ? l.balance_u : 0)
    @realized = (l != nil ? l.balance_r : 0)
  end
  
  def balance_unrealized
    $redis.hfetch hrapidkey, "balance_unrealized" do
      load_balance
      @unrealized
    end.to_i
  end
  
  def balance_unrealized= (v)
    $redis.hset hrapidkey, "balance_unrealized", v
  end
  
  def balance_realized
    $redis.hfetch hrapidkey, "balance_realized" do
      load_balance
      @realized
    end.to_i
  end
  
  def balance_realized= (v)
    $redis.hset hrapidkey, "balance_realized", v
  end

  def total_balance
    balance_unrealized + balance_realized
  end
  
  def reserve! (kind, id)
    $redis.hset hrapidkey, "reservation", kind.to_s + ":" + id.to_s
  end
  
  def unreserve!
    $redis.hdel hrapidkey, "reservation"
  end
  
  def is_reserved?
    ($redis.hget hrapidkey, "reservation") != nil
  end
  
  def get_reservation
    reserve = $redis.hget hrapidkey, "reservation"
    if reserve
      resp = reserve.split(":")
      if(resp[0].to_i == Transaction::KIND_ROOM)
        return Room.find(resp[1].to_i)
      end
    end
  end
  
  # account stuff
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
  
  def steam_name
    return "Hello" if Rails.env.test?
    begin
      fetch_steamapi
      return $redis.hget hrapidkey, "steamname"
    rescue NoSteamID
      return nil
    end
  end
  
  def steam_avatar_urls
    return "http:// http:// http://" if Rails.env.test?
    begin
      fetch_steamapi
      return $redis.hget hrapidkey, "avatar_urls"
    rescue NoSteamID
      return nil
    end
  end
end

