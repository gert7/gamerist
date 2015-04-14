class SteamidController < ApplicationController
  def add
    current_user.attach auth_hash
    redirect_to "/account"
  end
  
  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end
