# PayPal transaction reference

class Paypal < ActiveRecord::Base
  STATE_CREATED   = 1
  STATE_EXECUTED  = 2

  class PaymentCreationFailedException < Exception
  end

  belongs_to :user, inverse_of: :paypals

  def self.paypal_route
    "/paypal_callback"
  end

  # Make a Transaction, 
  def self.start_paypal_add(user, points, countrycode)
    (points >= 0) or throw ArgumentError
    country   = Gamerist::country(countrycode)
    subtotal  = points
    total     = subtotal*(1 + country[:vat])
    payment = PayPal::SDK::REST::Payment.new({
      intent: "sale",
      payer: {payment_method: "paypal"},
      transactions: [{
        amount: {
          total: "%.2f" % total,
          currency: country[:paypalcurrency].to_s,
          details: {
            subtotal: "%.2f" % subtotal,
            tax: "%.2f" % (total - subtotal),
            redirect_urls: request.host + request.port + Paypal::paypal_route
            } # details
          } # amount
      }] # transaction 1
    })
    unless payment.create
      raise PaymentCreationFailedException, payment.error
    end
    Paypal.new do |p| # very confusing names
      p.user      = user
      p.amount    = points
      p.subtotal  = subtotal
      p.tax       = total - subtotal
      p.state     = Paypal::STATE_CREATED
      p.sid       = a.id
      p.redirect  = a.links.detect{|v| v["method"] == "REDIRECT" }["href"]
    end
  end
  
  def finalize_paypal_add(payerid)
    payment = PayPal::SDK::REST::Payment.find(self.sid)
    Transaction::paypal_finalize(self.user, self.amount, self)
    # throw [self.user_id, self.amount, self]
    if(payment.execute(payer_id: payerid))
      self.state = Paypal::STATE_EXECUTED
      self.save!
    else
      errors.add("Failed to execute payment!")
    end
  end
end
