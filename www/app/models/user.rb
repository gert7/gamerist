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

  has_one :account, inverse_of: :user
  accepts_nested_attributes_for :account
  has_one :steamid, inverse_of: :user
  has_many :transactions, inverse_of: :user
  has_many :paypals, inverse_of: :user

  def name
    self.email
  end

  def attach_steam(access_token)
    steamuid = access_token['uid']
    @steamid = self.create_steamid(steamid: steamuid)
  end
  
  # unrealized + realized
  def load_balance
    l = Transaction.where(user_id: self.id).last
    Rails.cache.write cache_symbol("unrealized"), (l != nil ? l.balance_u : 0)
    Rails.cache.write cache_symbol("realized"), (l != nil ? l.balance_r : 0)
  end
  
  def balance_unrealized
    cache_fetch_symbol_else "unrealized" do load_balance; return Rails.cache.fetch cache_symbol("unrealized") end
  end
  
  def balance_realized
    cache_fetch_symbol_else "realized" do load_balance; return Rails.cache.fetch cache_symbol("realized") end
  end

  def total_balance
    balance_unrealized + balance_realized
  end
  
  # account stuff
  def fetch_avatar_id
    self.cache_fetch_symbol_else "avatar_id" do
      require 'open-uri'
      steamapik = $GAMERIST_API_KEYS["steam"]
      response = JSON.parse(open("http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=#{steamapik}&steamids=#{self.steamid.steamid}").read)
      response["response"]["players"][0]["avatar"][/avatars\/(.*)\./, 1]
    end
  end
end
