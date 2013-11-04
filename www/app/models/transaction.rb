class Transaction < ActiveRecord::Base
  
  STATE_INVALID    = 0
  STATE_INCOMPLETE = 1
  STATE_VALID      = 2

  TYPE_NONE   = 0
  TYPE_WAGER  = 1
  TYPE_PAYPAL = 2
  TYPE_COUPON = 4 # TODO
  
  belongs_to :user, inverse_of: :transaction
  
  def new(args)
    super.new
    Transaction.transaction do
      self.state    = args.state or throw
      self.user_id  = args.user_id or throw
      self.type     = args.type or throw
      self.detail   = args.detail or throw
      self.amount   = args.amount or throw
      lasttr      = Transaction.find(:last, user_id: tr.user_id)
      self.lastref  = lasttr.id
      self.balance  = lasttr.balance + tr.amount
      self.save
    end
  end
end

