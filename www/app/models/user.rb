class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_one :steamid, inverse_of: :user
  has_many :transactions, inverse_of: :user

  def attach_steam(access_token)
    steamuid = access_token['uid']
    @steamid = self.create_steamid(steamid: steamuid)
  end
  
  # unrealized + realized
  def load_balance
    l = Transaction.where(user_id: self.id).last
    if(l)
      Rails.cache.write cache_key("unrealized"), l.balance_u
      Rails.cache.write cache_key("realized"), l.balance_r
    else
      Rails.cache.write cache_key("unrealized"), 0
      Rails.cache.write cache_key("realized"), 0
    end
  end
  
  def balance_unrealized
    cache_fetch_key_else "unrealized" do load_balance end
  end
  
  def balance_realized
    cache_fetch_key_else "realized" do load_balance end
  end
  
  def balance_unrealized= (v)
    Rails.cache.write cache_key("unrealized"), v
  end
  
  def balance_realized= (v)
    Rails.cache.write cache_key("realized"), v
  end
  
  def total_balance
    balance_unrealized + balance_realized
  end
  
  def set_wager args
    args[:room]
  end
  
end
