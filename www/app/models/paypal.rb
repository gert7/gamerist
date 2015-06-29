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
  
  MIN_PURCHASE    = 5
  MAX_PURCHASE    = 100

  class PaymentCreationFailedException < Exception
  end

  belongs_to :user, inverse_of: :paypals

  def self.paypal_route
    "/paypal_callback"
  end

  def self.get_redir(p)
    p.links.detect{|v| v.method == "REDIRECT" }.href
  end

  MARGIN_FIXED_RATE  = 0 # not used
  MARGIN_MULT_PRETTY = 12
  MARGIN_MULT_RATE   = BigDecimal.new("1.0") + (BigDecimal.new(MARGIN_MULT_PRETTY.to_s) / BigDecimal.new("100.0"))
  puts "MULT RATE" + MARGIN_MULT_RATE.to_s
  
  require 'json_vat'
  require 'money'
  require 'money/bank/google_currency'
  require 'config/initializers/gamerist'
  
  Money::Bank::GoogleCurrency.ttl_in_seconds = 600
  Money.default_bank = Money::Bank::GoogleCurrency.new

  @@pointcost = Money.new(1_00, "EUR") # amount is in cents
  
  def self.country(code)
    defaultcountry = $gamerist_countrydata[0]
    countryo = (($gamerist_countrydata.find {|c| (code.to_s == c["threecode"].to_s) or (code.to_s == c["twocode"]) }) or defaultcountry)
    country  = countryo.clone
    puts country
    
    if country["twocode"] == "RX" or country["eu"] != 1
      puts "hello" + country["twocode"]
      country["vat"] = 0.00
    else
      c = JSONVAT.country(country["twocode"])
      country["vat"] = c.rate / 100
    end
    country["masspaycurrency"] = country["currency"]
    country["pointcost"] = @@pointcost.exchange_to(country["currency"].to_sym)
    return country
  end

  # Returns the correct payment properties for
  # the given country and point number
  # @param [Integer] points Number of points to be purchased
  # @param [Symbol] countrycode Three-letter country code, see ISO 3166-1
  # @return [Hash] Resulting payment info + tax info in BigDecimals! :currency :vat, in local currency the keys :subtotal, :total, :tax
  def self.calculate_payment(points, countrycode)
    throw "Number too large!" if points.to_s.length > 6
    puts points
    throw "Number out of range!" if points.to_i < Paypal::MIN_PURCHASE or points.to_i > Paypal::MAX_PURCHASE
    data      = Hash.new
    country   = Paypal::country(countrycode)
    data[:currency] = country["currency"]
    data[:subtotal] = (BigDecimal.new(points.to_s) + BigDecimal.new(Paypal::MARGIN_FIXED_RATE.to_s)) * BigDecimal.new(country["pointcost"].to_f.to_s) * BigDecimal.new(Paypal::MARGIN_MULT_RATE.to_f.to_s)
    data[:subrate]  = Paypal::MARGIN_MULT_PRETTY
    data[:total]    = data[:subtotal] * BigDecimal.new((1.0 + country["vat"].to_f).to_s)
    data[:tax]      = data[:total] - data[:subtotal]
    data[:vat]      = (country["vat"] * 100).to_i
    data[:countrycode] = country["twocode"]
    data[:countryname] = country["name"]
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

