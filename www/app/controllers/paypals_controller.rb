class PaypalsController < ApplicationController
  before_action :set_paypal, only: [:show]
  before_filter :authenticate_user!
  
  def new
  end

  # Accept a new PayPal query
  def create
    if(params[:debugmode] == "1")
      puts "hey"
      if(Rails.env.development?)
        Transaction.create do |t|
          t.user = current_user
          t.state = Transaction::STATE_FINAL
          t.kind  = Transaction::KIND_PAYPAL
          t.amount = params[:points]
          t.detail = 1
        end
      end
    else
      @paypal = Paypal::start_paypal_add(current_user, params[:points].to_i, :SWE)
    end
  end

  # User redirect
  def show
    pp = Paypal.find_by_id params[:id]
    pp.finalize_paypal_add(params[:PayerID]) ? flash[:notice] = pp.amount.to_s + " has been deposited to your account" : flash[:notice] = "Failed to deposit to account!"
    redirect_to controller: :welcome, action: :index
  end

  private
    def set_paypal
      @paypal = Paypal.find(params[:id])
    end
end
