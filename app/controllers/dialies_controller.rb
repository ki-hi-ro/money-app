class DialiesController < ApplicationController
  before_action :set_dialy, only: %i[ show edit update destroy ]

  # GET /dialies or /dialies.json
  def index
    @dialies = Dialy.all
  end

  # GET /dialies/1 or /dialies/1.json
  def show
  end

  # GET /dialies/new
  def new
    @dialy = Dialy.new
  end

  # GET /dialies/1/edit
  def edit
  end

  # POST /dialies or /dialies.json
  def create
    @dialy = Dialy.new(dialy_params)

    respond_to do |format|
      if @dialy.save
        format.html { redirect_to dialy_url(@dialy), notice: "Dialy was successfully created." }
        format.json { render :show, status: :created, location: @dialy }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @dialy.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dialies/1 or /dialies/1.json
  def update
    respond_to do |format|
      if @dialy.update(dialy_params)
        format.html { redirect_to dialy_url(@dialy), notice: "Dialy was successfully updated." }
        format.json { render :show, status: :ok, location: @dialy }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @dialy.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dialies/1 or /dialies/1.json
  def destroy
    @dialy.destroy

    respond_to do |format|
      format.html { redirect_to dialies_url, notice: "Dialy was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dialy
      @dialy = Dialy.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def dialy_params
      params.require(:dialy).permit(:date, :title, :text)
    end
end
