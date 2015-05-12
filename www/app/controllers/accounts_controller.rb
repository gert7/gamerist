class AccountsController < ApplicationController
  before_filter :authenticate_user!, only: [:show]

  def index
    current_user.save unless(not current_user or current_user.account)
    # @user.attach_steam "uid" => "76561197960435530"
    # if @user.steamid then
      # @avatar_uri = @user.fetch_avatar_id
    # end
    if current_user
      respond_to do |format|
        format.json { render json: { user_id: current_user.name, total_balance: current_user.total_balance } }
      end
    else
      respond_to do |format|
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
  
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def account_params
      params.require(:account).permit(:countrycode, :nickname, :dob, :firstname, :lastname, :paypaladdress, :user)
    end
end

