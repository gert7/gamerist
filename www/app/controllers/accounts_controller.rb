class AccountsController < ApplicationController
  before_filter :authenticate_user!, only: [:index]

  def index
    @user = current_user
    if @user.steamid then
      
    end
  end
end

