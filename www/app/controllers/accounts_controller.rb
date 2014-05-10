class AccountsController < ApplicationController
  before_filter :authenticate_user!, only: [:index]

  def show
    @user = params[:id] ? User.find(params[:id]) : current_user
    @user.attach_steam "uid" => "76561197960435530"
    if @user.steamid then
      @avatar_uri = @user.fetch_avatar_id
    end
  end
end

