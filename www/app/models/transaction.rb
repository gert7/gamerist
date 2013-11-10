class Transaction < ActiveRecord::Base
  
  STATE_INVALID    = 0
  STATE_INCOMPLETE = 1
  STATE_FINAL      = 2

  KIND_UNREALIZED = 0b000 # IN: R | OUT: U
  KIND_REALIZED   = 0b001 # IN: ANY OUT: R
  
  KIND_NONE       = 0b000
  KIND_ROOM       = 0b001 # winnings if positive, wager if negative
  KIND_PAYPAL     = 0b010
  KIND_COUPON     = 0b100 # TODO
  
  belongs_to :user, inverse_of: :transactions
  
  before_save do
    self.user.addto_primitives(self.amount, self.kind)
    lasttr        = Transaction.where(user_id: self.user_id).last
    if(lasttr)
      self.lastref  = lasttr.id
      self.balance  = lasttr.balance + self.amount
    else
      self.balance  = self.amount
    end
    if (self.balance < 0.0)
      throw ActiveRecord::Rollback
    end
  end
end

