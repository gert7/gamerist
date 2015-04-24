class WelcomeController < ApplicationController
  def index
    expires_in 5.months, public: true
    flash.delete :notice
    respond_to do |format|
      format.html { render action: 'index' }
    end
  end
end

