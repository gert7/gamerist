class WelcomeController < ApplicationController
  def index  
    expires_in 2.days, public: true
    flash.delete :notice
    respond_to do |format|
      format.html { render action: 'index' }
    end
  end
end

