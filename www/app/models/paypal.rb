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
  def self.start_paypal_add(user, points, countrycode, hostname)
    (points >= 0) or throw ArgumentError
    country   = Gamerist::country(countrycode)
    subtotal  = points
    total     = subtotal*(1 + country[:vat])
    tax       = total - subtotal
    pp        = Paypal.create
    subtotal_s= "%.2f".format(subtotal)
    total_s   = "%.2f".format(total)
    tax_s     = "%.2f".format(tax)
    
    pt = {
      intent: "sale",
      payer: {payment_method: "paypal"},
      redirect_urls: {
        return_url: $PAYPAL_SDK_RETURN_HOSTNAME + "/paypal/" + pp.id.to_s,
        cancel_url: $PAYPAL_SDK_RETURN_HOSTNAME
        }, # redirect_urls
      transactions: [{
        amount: {
          total: total_s,
          currency: country[:paypalcurrency].to_s,
          details: {
            subtotal: subtotal_s,
            tax: tax_s
            } # details
          } # amount
      }] # transaction 1
    }
    payment = PayPal::SDK::REST::Payment.new(pt)
    unless payment.create
      raise PaymentCreationFailedException, payment.error
    end
    pud = {user: user,
          amount: points,
          subtotal: subtotal, 
          tax: total - subtotal, 
          state: Paypal::STATE_CREATED, 
          sid: payment.id, 
          redirect: payment.links.detect{|v| v.method == "REDIRECT" }.href
          }
    pp.update(pud)
    return pp
  end
  
  def finalize_paypal_add(payerid)
    payment = PayPal::SDK::REST::Payment.find(self.sid)
    # throw [self.user_id, self.amount, self]
    if(payment.execute(payer_id: payerid))
      self.state = Paypal::STATE_EXECUTED
      self.save!
      Transaction::paypal_finalize(self.user, self.amount, self)
      return true
    end
    return false
  end
end
