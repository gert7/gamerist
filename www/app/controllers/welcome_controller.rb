class WelcomeController < ApplicationController
  def index  
    expires_in 2.days, public: true
    flash.delete :notice
    
    Room.last.declare_winning_team(3) # TODO remove!!!!
    Room.last.declare_team_scores [{"steamid" => "STEAM_0:1:18525940", "score" => 81}]
    
    respond_to do |format|
      format.html { render action: 'index' }
    end
  end
end

