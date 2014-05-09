# PayPal transaction reference

class Paypal < ActiveRecord::Base
  STATE_CREATED   = 1
  STATE_EXECUTED  = 2
  
  belongs_to :user, inverse_of: :paypals

  # Make a Transaction, 
  def self.start_paypal_add(user, points, countrycode)
    (points >= 0) or throw ArgumentError
    country   = Gamerist::country(countrycode)
    subtotal  = (points * country[:vat])
    total     = subtotal*(1 + country[:vat])
    
    payment = PayPal::SDK::REST::Payment.new({
      intent: "sale",
      payer: {payment_method: "paypal"},
      transactions: [{
        amount: {
          total: total.to_s,
          currency: country[:paypalcurrency].to_s,
          details: {
            subtotal: subtotal.to_s,
            tax: country[:vat].to_s
            } # details
          } # amount
      }] # transaction 1
    })
    
    a = payment.create
    Paypal.create do |p| # very confusing names
      p.recipient = user
      p.amount    = points
      p.subtotal  = subtotal
      p.tax       = total - subtotal
      p.state     = Paypal::STATE_CREATED
      p.sid       = payment.id
    end
    a.links.find{|v| v[:method] == "REDIRECT" }[:href]
  end
  
  def finalize_paypal_add(payerid)
    (am >= 0) or throw ArgumentError
    payment = PayPal::SDK::REST::Payment.find(self.sid)
    Transaction::paypal_finalize(self.recipient, self.amount, self)
    
    if(payment.execute(payer_id: payerid))
      self.state = Paypal::STATE_EXECUTED
      self.save!
    else
      errors.add("Failed to execute payment!")
    end
  end
end
