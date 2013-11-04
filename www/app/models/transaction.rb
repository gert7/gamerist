class Transaction < ActiveRecord::Base
  
  STATE_INVALID    = 0
  STATE_INCOMPLETE = 1
  STATE_VALID      = 2

  TYPE_NONE   = 0
  TYPE_WAGER  = 1
  TYPE_PAYPAL = 2
  TYPE_COUPON = 4 # TODO
  
  belongs_to :user
end
