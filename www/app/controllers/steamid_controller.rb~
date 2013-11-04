class Steamid < ApplicationController
  def attach
    current_user.attach auth_hash
    redirect_to "/account"
  end
  
  def get_info
    
  end
  
  protected

  def steam_api_key
    Gamerist::api_key["steam"]
  end

  def auth_hash
    request.env['omniauth.auth']
  end
end
