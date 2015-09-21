$gamerist_continentdata= JSON.parse(File.read(Rails.root.join("config", "continents.json")))

def get_continent(countryname)
  i = $gamerist_continentdata["countries"].find_index {|c| c["country"] == countryname }
  return $gamerist_continentdata["countries"][i]["continent"]
end

class RoomsController < ApplicationController
  before_action :set_room, only: [:show, :edit, :destroy]
  before_filter :authenticate_user!
  skip_before_action :verify_authenticity_token
  # GET /rooms
  # GET /rooms.json
  def index
    page         = params[:page].to_i
    @rooms       = Room.roomlist_range(page, page + 30)
    @roomslength = Room.roomlist_length
    respond_to do |format|
      format.json { render action: 'index' }
      format.html { render action: 'index' }
    end
  end

  # GET /rooms/1
  # GET /rooms/1.json
  def show
    respond_to do |format|
      format.json { render action: 'show', location: @room }
      if current_user and (res = current_user.get_reservation) and res.id != @room.id
        format.html { redirect_to :controller => 'rooms', :action => 'show', :id => res.id }
      else
        format.html { render action: 'show', location: @room }
      end
    end
  end

  # GET /rooms/new
  def new
    @room = Room.new
    res = current_user.get_reservation
    if res and res.class == Room and current_user.reservation_is_room?(res.id)
      respond_to do |format|
        format.html { redirect_to :controller => 'rooms', :action => 'show', :id => res.id }
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
    
    require "geocoder"
    Geocoder.configure(ip_lookup: :telize)
    Geocoder.configure(:cache => Redis.new)
    reported_country = Geocoder.search(request.remote_ip)[0].country
    reported_country ||= "Reserved"

    @room.server_region = get_continent(reported_country)

    respond_to do |format|
      if @room.save
        format.html { redirect_to @room, notice: 'Room was successfully created.' }
        format.json { render action: 'show', status: :created, location: @room }
      else
        format.html { render action: 'new' }
        format.json { render json: @room.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rooms/1
  # PATCH/PUT /rooms/1.json
  def update
    @room = Room.new(id: params[:id])
    params[:requestip] = request.remote_ip
    
    @room.update_xhr(current_user, params)
    @uniquesignature = params["uniquesignature"]
    respond_to do |format|
      format.html { redirect_to @room }
      format.json { render action: 'show', location: @room }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_room
      @room = Room.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def room_params
      params.require(:room).permit(:state, :map, :server, :game, :playercount, :wager)
    end
end
