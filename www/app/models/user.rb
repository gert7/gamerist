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
  
  def build_balance
    transactions = Transaction.find_by user_id: self.id
    balance   = 0
    transactions.each do |t|
      balance += t.amount
    end
    balance
  end
  
  def last_transaction
    Transaction.find_by(user_id: self.id).last
  end
  
  def fetch_balance
    last_transaction.balance
  end
  
end
