class Users::OauthCallbacksController < Devise::OmniauthCallbacksController
  protect_from_forgery except: [:steam, :failure]
  
  def attachsid(req)
    err = Steamid.attach_by_steam_callback(req)
    
    respond_to do |format|
      unless err
        format.html { redirect_to "/" }
      else
        format.html { redirect_to "/", :flash => { :error => err } }
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

