class PayoutsController < ApplicationController
  def new
    @payout = Payout.new
  end
  
  def create
    Transaction.paypal_payout(current_user.id, payout_params[:email], payout_params[:points])
  end
  
  def paydata
    @data = Payout.new(points: params[:points]).get_paydata
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_payout
      @payout = Payout.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def payout_params
      params.require(:payout).permit(:batchid, :points, :subtotal, :total, :margin, :currency, :user, :email)
    end
end
