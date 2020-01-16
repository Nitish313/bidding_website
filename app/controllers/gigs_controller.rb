class GigsController < ApplicationController
  def index
  end

  def new
    @gig = Gig.new
  end

  def create
    @gig = Gig.new(gig_params)
    if @gig.save
      flash[:success] = "New Gig posted"
      redirect_to gig_path(@gig)
    else
      flash[:danger] = "Something went wrong!"
      render 'new'
    end
  end

  def show
    @gig = Gig.find(params[:id])
  end

  private

    def gig_params
      params.require(:gig).permit(:name, :description, :budget, :location, :open)
    end
end