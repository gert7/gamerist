class AccountsController < ApplicationController
  before_action :set_account, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!, only: [:show]

  def index
    #current_user.save unless(not current_user or current_user.account)

    respond_to do |format|
      if current_user
        format.html { redirect_to "/accounts/" + current_user.id.to_s }
        continent = fetch_continent(request.remote_ip)
        format.json { render json: { user_id: current_user.name, total_balance: current_user.total_balance, country: fetch_continent_country(request.remote_ip), continent: continent, continent_available: Room.continent_exists?(continent) } }
      else
        format.html { redirect_to "/" }
        format.json { render json: { user_id: "nobody", total_balance: "nothing" } }
      end
    end
  end
  
  def unfreeze
    current_user.unreserve_from_room(current_user.reservation[1].to_i)
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
    @user  = current_user
    if @user.relevantgames
      @rooms = Room.find(@user.relevantgames.split(";").map do |gs|
        gs.to_i
      end)
      @games = Array.new
      @rooms.each do |r|
        mrules = r.crules
        pi     = mrules["players"].find_index{|p| p["id"].to_i == @user.id }
        player = mrules["players"][pi]
        @games << {winningteam: mrules["winningteam"].to_i, playerteam: player["team"].to_i, game: mrules["game"], map: mrules["map"], wager: mrules["wager"]}
      end
    end
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

