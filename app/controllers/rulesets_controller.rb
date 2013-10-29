class RulesetsController < ApplicationController
  before_action :set_ruleset, only: [:show, :edit, :update, :destroy]

  # GET /rulesets
  # GET /rulesets.json
  def index
    @rulesets = Ruleset.all
  end

  # GET /rulesets/1
  # GET /rulesets/1.json
  def show
  end

  # GET /rulesets/new
  def new
    @ruleset = Ruleset.new
  end

  # GET /rulesets/1/edit
  def edit
  end

  # POST /rulesets
  # POST /rulesets.json
  def create
    @ruleset = Ruleset.new(ruleset_params)

    respond_to do |format|
      if @ruleset.save
        format.html { redirect_to @ruleset, notice: 'Ruleset was successfully created.' }
        format.json { render action: 'show', status: :created, location: @ruleset }
      else
        format.html { render action: 'new' }
        format.json { render json: @ruleset.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rulesets/1
  # PATCH/PUT /rulesets/1.json
  def update
    respond_to do |format|
      if @ruleset.update(ruleset_params)
        format.html { redirect_to @ruleset, notice: 'Ruleset was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @ruleset.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rulesets/1
  # DELETE /rulesets/1.json
  def destroy
    @ruleset.destroy
    respond_to do |format|
      format.html { redirect_to rulesets_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ruleset
      @ruleset = Ruleset.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def ruleset_params
      params.require(:ruleset).permit(:map_id, :playercount)
    end
end
