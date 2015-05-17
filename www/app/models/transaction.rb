# == Schema Information
#
# Table name: transactions
#
#  id         :integer          not null, primary key
#  state      :integer
#  user_id    :integer
#  lastref    :integer
#  kind       :integer
#  detail     :integer
#  amount     :integer
#  balance_u  :integer
#  balance_r  :integer
#  created_at :datetime
#  updated_at :datetime
#

class Transaction < ActiveRecord::Base
  
  STATE_INVALID    = 0
  STATE_INCOMPLETE = 1
  STATE_FINAL      = 2

  KIND_UNREALIZED = 0b0000 # IN: R | OUT: U
  KIND_REALIZED   = 0b0001 # IN: U then R OUT: R
  
  KIND_NONE       = 0b0000
  KIND_ROOM       = 0b0001 # winnings if positive, wager if negative
  KIND_PAYPAL     = 0b0010
  KIND_COUPON     = 0b0100 # TODO
  
  belongs_to :user, inverse_of: :transactions
  
  def realized_kind?
    (self.kind & 0b0001) == 1
  end
  
  # First unrealized, then realized
  def trickle_down_score (lastu, lastr)
    if(lastu < (0 - self.amount))
      self.balance_u = 0
      self.balance_r = lastr + (lastu + self.amount) # remaining
    else
      self.balance_u = lastu + self.amount
      self.balance_r = lastr
    end
  end

  def kind_handler()
    lasttr = Transaction.where(user_id: self.user_id).last
    case [self.amount >= 0, self.realized_kind?, lasttr != nil]
    when [true, true, true], [false, false, true] # wager win (amount positive) or cash out (amount negative)
      self.balance_r = lasttr.balance_r + self.amount
      self.balance_u = lasttr.balance_u
    when [false, true, true] # new wager
      trickle_down_score(lasttr.balance_u, lasttr.balance_r)
    when [true, false, true] # add funds
      self.balance_u = lasttr.balance_u + self.amount
      self.balance_r = lasttr.balance_r
    when [true, true, false]
      self.balance_r = self.amount
      self.balance_u = 0
    when [false, true, false], [false, false, false]
      raise ActiveRecord::Rollback, "Negative balance!"
    when [true, false, false]
      self.balance_u = self.amount
      self.balance_r = 0
    end
    lasttr ? lasttr.id : nil
  end
  
  before_save do
    #if self.amount < 0 then    
      #throw [self.amount >= 0, self.realized_kind?, lasttr != nil]
    #end
    l = kind_handler()
     
    if(self.balance_u < 0 or self.balance_r < 0)
      raise ActiveRecord::Rollback, "Balance becomes less than 0: U = #{balance_u} R = #{balance_r}"
    end
    
    # update the cache
    self.user.balance_unrealized = self.balance_u
    self.user.balance_realized = self.balance_r
    self.lastref = l or 0
  end

  # try to generalize
  def self.paypal_finalize(user, amount, detail)
    Transaction.create do |t|
      t.user    = user
      t.amount  = amount
      t.state   = Transaction::STATE_FINAL
      t.kind    = Transaction::KIND_PAYPAL
      t.detail  = detail
    end
  end
end

