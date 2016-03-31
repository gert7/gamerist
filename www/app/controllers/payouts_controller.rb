# == Schema Information
#
# Table name: payouts
#
#  id         :integer          not null, primary key
#  batchid    :string(255)
#  points     :integer
#  subtotal   :decimal(16, 2)
#  total      :decimal(16, 2)
#  margin     :decimal(16, 2)
#  currency   :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#

class PayoutsController < ApplicationController
  def new
    @payout = Payout.new
  end
  
  def create
    x = Transaction.paypal_payout(current_user.id, payout_params[:email], payout_params[:points])
    if x.class == Hash
      flash[:alert] = "PayPal Fatal Error: " + x["error"] + ". Please contact Support"
    elsif x.class == Fixnum and x > 0
      flash[:notice] = payout_params[:points] + " Points have been withdrawn from Your account!"
    end
    
    redirect_to "/payouts/new"
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
