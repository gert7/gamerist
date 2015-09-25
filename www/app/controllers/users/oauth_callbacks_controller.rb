class Users::OauthCallbacksController < Devise::OmniauthCallbacksController
  protect_from_forgery except: [:steam, :failure]
  
  def attachsid(req)
    begin
      Steamid.attach_by_steam_callback(current_user, req)
    rescue Steamid::UserNotLoggedIn
      @err = "User not logged in!"
    rescue Steamid::SteamIDNotInRequest
      @err = "Steam ID not found in request!"
    rescue Steamid::SteamIDNotNumeric
      @err = "Steam ID is not numeric!"
    end
    
    respond_to do |format|
      unless @err
        format.html { redirect_to "/" }
      else
        format.html { redirect_to "/", :flash => { :error => @err } }
      end
    end
  end
  
  def steam
    attachsid(request.env["omniauth.auth"])
  end
  
  def failure
    attachsid(request.env["omniauth.auth"])
  end
end

