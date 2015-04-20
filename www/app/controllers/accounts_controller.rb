class AccountsController < ApplicationController
  before_filter :authenticate_user!, only: [:index]

  def show
    @user = params[:id] ? User.find(params[:id]) : current_user
    @user.save unless(@user.account)
    # @user.attach_steam "uid" => "76561197960435530"
    # if @user.steamid then
      # @avatar_uri = @user.fetch_avatar_id
    # end
    respond_to do |format|
      format.json { render json: { user_id: current_user.name, total_balance: current_user.total_balance } }
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

