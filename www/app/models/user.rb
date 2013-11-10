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
  
  def last_transaction
    Rails.cache.fetch cache_key("last_transaction") do
      Transaction.find_by(user_id: self.id).last
    end
  end
  
  def get_balance # unrealized + realized, i.e. room money
    balance_realized + balance_unrealized + balance_ded_realized + balance_ded_unrealized
  end
  
  # Four balance primitives
  
  def balance_realized
    Rails.cache.fetch cache_key("balance_realized") do
      Transaction.where("user_id = ? AND (kind ^ ? ^ 1) = 1", self.id, Transaction::KIND_REALIZED).sum("amount")
    end
  end
  
  def balance_unrealized
    Rails.cache.fetch cache_key("balance_unrealized") do
      Transaction.where("user_id = ? AND (kind ^ ? ^ 1) = 1", self.id, Transaction::KIND_UNREALIZED).sum("amount")
    end
  end
  
  def balance_ded_unrealized
    Rails.cache.fetch cache_key("balance_unrealized_deducted") do
      Transaction.where("user_id = ? AND (balance < 0.0)", self.id).sum("amount")
    end
  end
  
  def balance_ded_realized
    Rails.cache.fetch cache_key("balance_realized_deducted") do
      Transaction.where("user_id = ? AND (balance < 0.0)", self.id).sum("amount")
    end
  end
  
  def addto_primitives(am, kind)
    case [am >= 0, ~(kind ^ Transaction::KIND_REALIZED)]
    when [true, true]
      Rails.cache.set cache_key("balance_realized"), balance_ + am
    when [true, false]
      Rails.cache.set cache_key("balance_unrealized"), balance_ + am
    when [false, true]
      Rails.cache.set cache_key("balance_ded_unrealized"), balance_ + am
    when [false, false]
      Rails.cache.set cache_key("balance_ded_"), balance_ + am
    end
  end
  
  def set_wager args
    args[:room]
  end
  
  def cache_key(k)
    "user-#{self.id}[#{k}]"
  end
  
end
