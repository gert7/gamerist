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

require 'agis'

class Transaction < ActiveRecord::Base
  include Agis
  
  STATE_INVALID    = 0
  STATE_INCOMPLETE = 1
  STATE_FINAL      = 2

  KIND_UNREALIZED = 0b0000 # IN: R | OUT: U
  KIND_REALIZED   = 0b0001 # IN: U then R OUT: R
  
  KIND_NONE       = 0b0000
  KIND_ROOM       = 0b0001 # IN: U then R OUT: R
  KIND_PAYPAL     = 0b0010 # IN: R | OUT: R
  KIND_COUPON     = 0b0100 # OUT: U
  
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

  # Ignores overdraft
  def kind_handler()
    lasttr = Transaction.where(user_id: self.user_id).last
    totr   = lasttr ? lasttr.balance_r : 0
    totu   = lasttr ? lasttr.balance_u : 0
    
    if self.kind == KIND_ROOM
      if self.amount >= 0
        self.balance_r = totr + self.amount
        self.balance_u = totu
      elsif self.amount < 0
        trickle_down_score(totu, totr)
      end
    elsif self.kind == KIND_PAYPAL
      self.balance_r = totr + self.amount
      self.balance_u = totu
    elsif self.kind == KIND_COUPON
      self.balance_r = totr
      self.balance_u = totu + self.amount
    end
    lasttr ? lasttr.id : nil
  end
  
  before_save do
    #if self.amount < 0 then    
      #throw [self.amount >= 0, self.realized_kind?, lasttr != nil]
    #end
    
    raise ActiveRecord::Rollback if ((self.kind == KIND_ROOM and self.user.reservation_lives? and not self.user.reservation_is_room?(self.detail)) or (self.kind == KIND_PAYPAL and self.user.reservation_lives? and not self.user.reservation_is_paypal?(self.detail)) and self.amount < 0)
    
    l = kind_handler()
    
    if(self.balance_u < 0 or self.balance_r < 0)
      raise ActiveRecord::Rollback, "Balance becomes less than 0: U = #{balance_u} R = #{balance_r}"
    end
    
    # update the cache
    self.user.balance_unrealized = self.balance_u
    self.user.balance_realized = self.balance_r
    self.lastref = l or 0
  end
  
  def agis_id
    self.user_id
  end
  
  # Thread-unsafe method used in make_transaction and elsewhere
  def self.perform_unique_transaction(hash)
    puts hash
    trf = Transaction.find_by(user_id: hash[:user_id], kind: hash[:kind], detail: hash[:detail])
    return trf.id if trf
    tr  = Transaction.new(hash)
    tr.save!
    puts tr.id
    return tr.id
  end
  
  def amake_transaction(hash)
    # if it was already made
    return Transaction.perform_unique_transaction(hash)
  end
  
  # Thread-safe version of Transaction#create
  def self.make_transaction(hash)
    mh = {user_id: hash[:user_id], amount: hash[:amount], state: hash[:state], kind: hash[:kind], detail: hash[:detail]}
    dum = Transaction.new(mh) # to hell with this!
    return Transaction.find(dum.acall($redis, :amake_transaction, mh))
  end

  # try to generalize
  #def self.paypal_finalize(user, amount, detail)
  #  Transaction.make_transaction(user_id: user.id, amount: amount, detail: detail, state: Transaction::STATE_FINAL, kind: Transaction::KIND_PAYPAL)
  #end
  
  def apaypal_finalize(payerid, ppid)
    payp = Paypal.find(ppid)
    ux   = User.new(id: payp.user_id)
    return false unless ux.reserve_paypal!(ppid)
    trid = Transaction.perform_unique_transaction(user_id: payp.user_id, amount: payp.amount, kind: Transaction::KIND_PAYPAL, detail: ppid, state: Transaction::STATE_FINAL)
    payp.state = Paypal::STATE_EXECUTED
    payp.save!
    payment = PayPal::SDK::REST::Payment.find(payp.sid)
    payment.execute(payer_id: payerid)
    ux.unreserve_from_paypal(ppid)
    return trid
  end

  def self.paypal_finalize(payerid, pp)
    mh  = {user_id: 1, amount: 1, state: Transaction::STATE_INVALID, kind: 1, detail: 1}
    dum = Transaction.new(mh)
    return Transaction.find(dum.acall($redis, :apaypal_finalize, payerid, pp.id))
  end
  
  after_initialize do
    agis_defm1 :amake_transaction
    agis_defm2 :apaypal_finalize
  end
end

