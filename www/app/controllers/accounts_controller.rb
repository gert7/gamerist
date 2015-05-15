class AccountsController < ApplicationController
  before_action :set_account, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!, only: [:show]

  def index
    current_user.save unless(not current_user or current_user.account)

    respond_to do |format|
      if current_user
        format.html { format.html { render action: 'show', location: current_user } }
        format.json { render json: { user_id: current_user.name, total_balance: current_user.total_balance } }
      else
        format.html { redirect_to "/" }
        format.json { render json: { user_id: "nobody", total_balance: "nothing" } }
      end
    end
  end
  
  def unfreeze
    respond_to do |format|
      if(res = current_user.get_reservation)
        if(res.class == Room)
          format.html {redirect_to res}
        end
      else
        format.html {redirect_to "/"}
      end
    end
  end

  def paypal_callback
  end
  
  def show
  end
  
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def account_params
      params.require(:account).permit(:countrycode, :nickname, :dob, :firstname, :lastname, :paypaladdress, :user)
    end
    
    def set_account
      @account = Account.find_by(user_id: params[:id])
    end
end

