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

  # Returns the correct payment properties for
  # the given country and point number
  # @param [Integer] points Number of points to be purchased
  # @param [Symbol] countrycode Three-letter country code, see ISO 3166-1
  # @return [Hash] Resulting payment info + tax info in BigDecimals! :currency :vat, in local currency the keys :subtotal, :total, :tax
  def self.calculate_payment(points, countrycode)
    data      = Hash.new
    country   = Gamerist::country(countrycode)
    data[:currency] = country["currency"]
    data[:subtotal] = (BigDecimal.new(points.to_s) + BigDecimal.new(Gamerist::MARGIN_FIXED_RATE.to_s)) * BigDecimal.new(country["pointcost"].to_f.to_s) * BigDecimal.new(Gamerist::MARGIN_MULT_RATE.to_f.to_s)
    data[:total]    = data[:subtotal] * BigDecimal.new((1.0 + country["vat"].to_f).to_s)
    data[:tax]      = data[:total] - data[:subtotal]
    data[:vat]      = country["vat"]
    data
  end

  # Create a new possible Paypal payment.
  # This does not need to be fulfilled or remembered
  # @param [User] user Instance of the recipient user
  # @param [Integer] points Amount of points to be received
  # @param [String] countrycode Country code in three-letter ISO 3166-1
  # @return [Paypal] A new Paypal instance
  def self.start_paypal_add(user, points, countrycode)
    (points >= 0) or throw ArgumentError

    data = Paypal.calculate_payment(points, countrycode)
    pp   = Paypal.create
    
    subtotal_s = "%.2f" % data[:subtotal]
    total_s    = "%.2f" % data[:total]
    tax_s      = "%.2f" % data[:tax]

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
          currency: data[:currency].to_s,
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
          subtotal: data[:subtotal],
          tax: data[:tax], 
          state: Paypal::STATE_CREATED, 
          sid: payment.id, 
          redirect: get_redir(payment)
          }
    pp.update(pud)
    return pp
  end
  
  # Finish a Paypal payment with a payerid
  # received from PayPal
  # @param [String] payerid Payerid received from PayPal API
  # @return [Transaction] A new Transaction object for the user
  def finalize_paypal_add(payerid)
    return Transaction::paypal_finalize(payerid, self)
    #payment = PayPal::SDK::REST::Payment.find(self.sid)
    # throw [self.user_id, self.amount, self]
    #if(self.state == Paypal::STATE_CREATED and payment.execute(payer_id: payerid))
    #  self.state = Paypal::STATE_EXECUTED
    #  unless self.save
    #    throw "CAN'T SAVE YO"
    #    return false
    #  end
    #  Transaction::paypal_finalize(self.user, self.amount, self)
    #  return true
    #end
    #return false
  end
end

