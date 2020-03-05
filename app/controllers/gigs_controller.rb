class GigsController < ApplicationController
  before_action :logged_in_user, except: [:index, :search, :show]
  before_action :only_clients, only: [:new, :create]
  before_action :correct_user, only: [:edit, :update, :destroy]
  def index
    @gigs = Gig.order_list(params[:sort_by]).includes_categories.paginate(page: params[:page])
  end

  def new
    @gig = Gig.new
  end

  def create
    @gig = Gig.new(gig_params)
    @gig.user = current_user
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
    @proposals = @gig.proposals.order_by_date
    @awarded_proposal = Proposal.where(id: @gig.awarded_proposal).first
  end

  def edit
  end

  def update
    @gig.update(gig_params)
    flash[:success] = "Gig successfully updated."
    redirect_to gig_path(@gig)
  end

  def destroy
    @gig.destroy
    flash[:success] = "Gig successfully deleted."
    if current_user.admin?
      redirect_to gigs_path
    else
      redirect_to :mygigs
    end 
  end

  def search
    if params[:category].blank? && params[:search].blank?
      @gigs = Gig.order_by_date.includes_categories.paginate(page: params[:page])
    else
      @gigs = Gig.search(params).includes_categories.paginate(page: params[:page])
    end
  end

  def mygigs
    if current_user.role == "Client"
      @gigs = Gig.where(user_id: current_user).order_by_date.includes_categories
    else
      redirect_to user_path(current_user)
      flash[:warning] = "Freelancers are not allowed to have any gigs."
    end
  end

  private

    def gig_params
      params.require(:gig).permit(:name, :description, :budget, :location, :open, :category_id, :skill_list, :awarded_proposal)
    end

    def only_clients
      unless current_user.role == "Client"
        flash[:warning] = "You can't post a gig unless you are a Client."
        redirect_to gigs_path(@gigs)
      end
    end

    def correct_user
      @gig = Gig.find(params[:id])
      unless(current_user == @gig.user || current_user.admin?)
        flash[:warning] = "You are neither the admin nor the owner of this gig!"
        redirect_to @gig
      end
    end
end