class Paypal < ActiveRecord::Base
  STATE_CREATED   = 1
  STATE_EXECUTED  = 2
  
  belongs_to :user, inverse_of: :paypals
  
  def start_paypal_add(user, points)
    (points >= 0) or throw ArgumentError
    country   = Gamerist::country(self.countrycode)
    subtotal  = (points * (country.vat - country.vat * country.compensation))
    total     = subtotal*(1 + country.vat)
    
    payment = PayPal::SDK::Rest::Payment.new({
      intent: "sale",
      payer: {payment_method: "paypal"},
      transactions: [{
        amount: {
          total: total.to_s,
          currency: country.paypalcurrency.to_s,
          details: {
            subtotal: subtotal.to_s,
            tax: country.vat.to_s
            } # details
          } # amount
      }] # transaction 1
    })
    
    payment.create
    Paypal.create do |p| # very confusing names
      p.recipient = user
      p.amount    = points
      p.subtotal  = subtotal
      p.tax       = total - subtotal
      p.state     = Paypal::STATE_CREATED
      p.sid       = payment.id
    end
    payment.links.find{|v| v.method == "REDIRECT" }.href
  end
  
  def finalize_paypal_add(pp, payerid)
    (am >= 0) or throw ArgumentError
    payment = PayPal::SDK::Rest::Payment.find(pp.sid)
    Transaction.create do |t|
      t.user    = self
      t.amount  = pp.amount
      t.state   = Transaction::STATE_FINAL
      t.kind    = Transaction::KIND_PAYPAL
      t.detail  = pp.id
    end
    
    if(payment.execute(payer_id: payerid))
      pp.state = Paypal::STATE_EXECUTED
    else
      errors.add("Failed to execute payment!")
    end
  end
end