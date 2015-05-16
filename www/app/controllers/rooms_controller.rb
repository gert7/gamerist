class RoomsController < ApplicationController
  before_action :set_room, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!
  skip_before_action :verify_authenticity_token
  # GET /rooms
  # GET /rooms.json
  def index
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
  end

  # GET /rooms/1/edit
  def edit
  end

  # POST /rooms
  # POST /rooms.json
  def create
    @room = Room.new(room_params)

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
    @room.update_xhr(current_user, params)
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
