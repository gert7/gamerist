class AccountsController < ApplicationController
  before_filter :authenticate_user!, only: [:index]

  def show
    @user = params[:id] ? User.find(params[:id]) : current_user
    @user.attach_steam "uid" => "76561197960435530"
    if @user.steamid then
      @avatar_uri = @user.fetch_avatar_id
    end
  end

  def start_paypal_add(user, points, countrycode)
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

  def paypal_callback
  end
end

