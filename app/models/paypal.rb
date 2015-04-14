# == Schema Information
#
# Table name: paypals
#
#  id         :integer          not null, primary key
#  amount     :decimal(8, 2)
#  subtotal   :decimal(8, 2)
#  tax        :decimal(8, 2)
#  state      :integer
#  user_id    :integer
#  sid        :string(255)
#  redirect   :string(255)
#  created_at :datetime
#  updated_at :datetime
#

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

  def self.get_redir(p)
    p.links.detect{|v| v.method == "REDIRECT" }.href
  end

  # Make a Transaction, 
  def self.start_paypal_add(user, points, countrycode)
    (points >= 0) or throw ArgumentError
    country   = Gamerist::country(countrycode)
    subtotal  = points
    total     = subtotal*(1 + country[:vat])
    tax       = total - subtotal
    pp        = Paypal.create
    subtotal_s= "%.2f" % subtotal
    total_s   = "%.2f" % total
    tax_s     = "%.2f" % tax
    
    pt = {
      intent: "sale",
      payer: {payment_method: "paypal"},
      redirect_urls: {
        return_url: $PAYPAL_SDK_RETURN_HOSTNAME + "/paypals/" + pp.id.to_s,
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
          redirect: get_redir(payment)
          }
    pp.update(pud)
    return pp
  end
  
  def finalize_paypal_add(payerid)
    payment = PayPal::SDK::REST::Payment.find(self.sid)
    # throw [self.user_id, self.amount, self]
    if(self.state == Paypal::STATE_CREATED and payment.execute(payer_id: payerid))
      self.state = Paypal::STATE_EXECUTED
      unless self.save
        throw "CAN'T SAVE YO"
        return false
      end
      Transaction::paypal_finalize(self.user, self.amount, self)
      return true
    end
    return false
  end
end
