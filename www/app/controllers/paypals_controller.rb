class PaypalsController < ApplicationController
  before_action :set_paypal, only: [:show]
  before_filter :authenticate_user!
  
  def new
    if current_user.reservation_lives?
      flash[:alert] = "You are currently reserved!"
      redirect_to controller: :welcome, action: :index 
    else
      expires_in 2.days, public: true
      flash.delete :notice
    end
  end

  # Accept a new PayPal query
  def create
    #if(params[:debugmode] == "1")
    #  puts "hey"
    #  if(Rails.env.development?)
    #    Transaction.create do |t|
    #      t.user = current_user
    #      t.state = Transaction::STATE_FINAL
    #      t.kind  = Transaction::KIND_PAYPAL
    #      t.amount = params[:points]
    #      t.detail = 1
    #    end
    #  end
    #else
    require "geocoder"
    countrycode = Geocoder.search(request.remote_ip)[0].country_code
    threecode   = Paypal::country(countrycode)["threecode"]
    points      = params[:points].to_i
    if points > 0
      paypal      = Paypal::start_paypal_add(current_user, points, threecode)
      redirect_to paypal.redirect if paypal
    else
      throw "Points is not a positive integer!"
    end
    #end
  end

  # User redirect
  def show
    pp = Paypal.find_by_id params[:id]
    pp.finalize_paypal_add(params[:PayerID]) ? flash[:notice] = pp.amount.to_i.to_s + " Points have been deposited to your account" : flash[:notice] = "Failed to deposit to account!"
    redirect_to controller: :accounts, action: :index
  end
  
  def paydata
    require "geocoder"
    countrycode = Geocoder.search(request.remote_ip)[0].country_code
#    puts params
    @data = Paypal.calculate_payment(params[:points], countrycode)
  end

  private
    def set_paypal
      @paypal = Paypal.find(params[:id])
    end
end
