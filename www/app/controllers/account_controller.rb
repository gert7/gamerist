class AccountController < ApplicationController
  before_filter :authenticate_user!, only: [:index]

  def index
    @user = current_user
    if @user.steamid not nil
      
    end
  end
end

