class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :reload_modifiers, :check_country
  
  def reload_modifiers
    Modifier.update_modifiers
  end
  
  def check_country
    continent = fetch_continent(request.remote_ip)
    unless Room.continent_exists?(continent)
      respond_to do |format|
        format.html { render "welcome/index", alert: "Gamerist is Not Available in Your Country" }
        format.json { render :json => {:message => "Nothing"}, alert: "Gamerist is Not Available in Your Country" }
      end
    end
  end
  
  # before_filter :expireflash
  
  #def expireflash
  #expires_now if(flash[:notice] or flash[:alert])
  #  puts flash[:notice]
  #end
end

