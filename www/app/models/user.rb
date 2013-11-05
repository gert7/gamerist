class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_one :steamid, inverse_of: :user
  has_many :transactions

  def attach_steam(access_token)
    steamuid = access_token['uid']
    @steamid = self.create_steamid(steamid: steamuid)
  end
  
  def get_balance
    transactions = Transaction.where(user_id: self.id, state: Transaction::STATE_FINAL)
    balance   = 0
    transactions.each do |t|
      balance += t.amount
    end
    balance
  end
  
  def uncertain_balance
    balance
  end
  
  def last_transaction
    Transaction.find_by(user_id: self.id).last
  end
  
  def fetch_balance
    last_transaction.balance
  end
  
  def set_wager args
    args[:room]
  end
  
  def redis_usertable k
    "user-#{self.id}[#{k}]"
  end
  
end
