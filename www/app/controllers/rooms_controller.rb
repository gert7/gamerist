# == Schema Information
#
# Table name: rooms
#
#  id         :integer          not null, primary key
#  state      :integer
#  created_at :datetime
#  updated_at :datetime
#  rules      :text
#

$gamerist_continentdata= JSON.parse(File.read(Rails.root.join("config", "continents.json")))

class RoomsController < ApplicationController
  before_action :set_room, only: [:show, :edit, :destroy]
  before_filter :authenticate_user!
  skip_before_action :verify_authenticity_token
  # GET /rooms
  # GET /rooms.json
  def index
    page         = params[:page].to_i
    @user_region = fetch_continent(request.remote_ip)
    @rooms       = RoomList.get_roomlist_by_continent(@user_region)
    @roomslength = @rooms.count
    
    respond_to do |format|
      format.json { render action: 'index' }
      format.html { render action: 'index' }
    end
  end

  # GET /rooms/1
  # GET /rooms/1.json
  def show
    expires_in 2.days, public: true
    flash.delete :notice
    @user_region = fetch_continent(request.remote_ip)
    
    respond_to do |format|
      if @room
        format.json { render action: 'show', location: @room }
        if current_user and (res = current_user.get_reservation) and res.id != @room.id
          format.html { redirect_to :controller => 'rooms', :action => 'show', :id => res.id }
        else
          format.html { render action: 'show', location: @room }
        end
      else
        format.json { redirect_to "/" }
        format.html { redirect_to "/" }
      end
    end
  end

  # GET /rooms/new
  def new
    expires_in 1.days, public: true
    flash.delete :notice
    @room = Room.new
    res = current_user.get_reservation
    
    @map_options_tf2 = $gamerist_mapdata["games"][0]["maps"].map do |m| m["name"] end
    @map_options_css = $gamerist_mapdata["games"][1]["maps"].map do |m| m["name"] end
    
    if res and res.class == Room and current_user.reservation_is_room?(res.id)
      respond_to do |format|
        format.html { redirect_to :controller => 'rooms', :action => 'show', :id => res.id }
      end
    elsif current_user.steamid == nil
      respond_to do |format|
        flash[:alert] = "Please add a Steam ID!"
        format.html { redirect_to controller: "accounts", action: "index" }
      end
    end
  end

  # GET /rooms/1/edit
  def edit
  end
  
  # POST /rooms
  # POST /rooms.json
  def create
    @room = Room.new(room_params)
    @room.server_region = fetch_continent(request.remote_ip)
    
    @map_options_tf2 = $gamerist_mapdata["games"][0]["maps"].map do |m| m["name"] end
    @map_options_css = $gamerist_mapdata["games"][1]["maps"].map do |m| m["name"] end
    
    respond_to do |format|
      if Room.continent_exists?(@room.server_region) or (not Rails.env.production?)
        if room_params[:wager].to_i <= current_user.total_balance
          x = @room.save
          if x
            format.html { redirect_to @room, notice: 'Room was successfully created.' }
            format.json { render action: 'show', status: :created, location: @room }
          else
            puts @room.errors.full_messages
            format.html { redirect_to '/rooms/new' }
            format.json { redirect_to '/rooms/new' }
          end
        else
          flash[:alert] = "Wager too high for this user!"
          format.html { render action: 'new' }
          format.json { render json: "Wager too high for this user!", status: :unprocessable_entity }
        end
      else # no such region available
        flash[:alert] = "No server available for this region"
        format.html { render action: 'new' }
        format.json { render json: "No server available for this region", status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rooms/1
  # PATCH/PUT /rooms/1.json
  def update
    @room = Room.new(id: params[:id])
    @room = Room.find(params[:id]) if @room.rules == nil
    
    params[:requestip] = request.remote_ip
    
    @user_region = fetch_continent(request.remote_ip)

    @room.update_xhr(current_user, params, @user_region)
    @uniquesignature = params["uniquesignature"]
    respond_to do |format|
      format.html { redirect_to @room }
      format.json { render action: 'show', location: @room }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_room
      begin
        @room = Room.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        @room = nil
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def room_params
      params.require(:room).permit(:state, :map, :server, :game, :playercount, :wager)
    end
end

