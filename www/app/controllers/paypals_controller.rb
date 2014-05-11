class PaypalsController < ApplicationController
  before_action :set_paypal, only: [:show]
  
  def new
  end

  # Accept a new PayPal query
  def create
    @paypal = Paypal::start_paypal_add(current_user, params[:points].to_i, :SWE, request.host)
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
