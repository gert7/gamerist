class Transaction < ActiveRecord::Base
  
  STATE_INVALID    = 0
  STATE_INCOMPLETE = 1
  STATE_FINAL      = 2

  KIND_NONE   = 0
  KIND_WAGER  = 1
  KIND_PAYPAL = 2
  KIND_COUPON = 4 # TODO
  
  belongs_to :user, inverse_of: :transactions
  
  before_save do
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

