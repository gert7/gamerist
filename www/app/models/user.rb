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

  def attach_steam(access_token)
    steamuid = access_token['uid']
    @steamid = self.create_steamid(steamid: steamuid)
  end
  
  # unrealized + realized
  def load_balance
    l = Transaction.where(user_id: self.id).last
    Rails.cache.write cache_key("unrealized"), (l != nil ? l.balance_u : 0)
    Rails.cache.write cache_key("realized"), (l != nil ? l.balance_r : 0)
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
  
  def finalize_paypal_cashout(am, pp)
  end
  
end
