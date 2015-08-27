class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :reload_modifiers
  
  def reload_modifiers
    puts "RELOADING MODIFIERS"
    Modifier.update_modifiers
  end
  
  # before_filter :expireflash
  
  #def expireflash
  #expires_now if(flash[:notice] or flash[:alert])
  #  puts flash[:notice]
  #end
end

