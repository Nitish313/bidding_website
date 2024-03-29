class ProposalsController < ApplicationController
  before_action :logged_in_user, only: [:create, :myproposals, :index]
  before_action :only_freelancers, only: [:create, :myproposals]
  before_action :correct_user, only: [:destroy]
  before_action :only_admin, only: [:index]

  def index
    @users = User.activated_freelancers
    @proposals = Proposal.paginate(page: params[:page], per_page: 20)
  end

  def create
    @gig = Gig.find(params[:gig_id])
    @proposal = @gig.proposals.build(proposal_params)
    @proposal.user = current_user
    if @proposal.valid?
      @proposal.save
      flash[:success] = "Proposal successfully submitted."
    else
      flash[:danger] = @proposal.errors.full_messages.to_sentence
    end
    redirect_to @proposal.gig
  end

  def myproposals
    @proposals = Proposal.where(user_id: current_user.id).order_by_date.includes_associations
  end

  def show
    @proposal = Proposal.includes_associations.find(params[:id])
  end

  def destroy
    @proposal = Proposal.find(params[:id])
    @proposal.destroy
    flash[:success] = "Proposal successfully deleted."
    if current_user == @proposal.user
      redirect_to myproposals_path
    elsif current_user.admin?
      redirect_to proposals_path
    end
        
  end

  private
    def proposal_params
      params.require(:proposal).permit(:name, :bid, :description)
    end

    def only_freelancers
      unless current_user.role == "Freelancer"
        flash[:warning] = "You need to be the owner as well as a freelancer to view this page."
        redirect_to current_user
      end
    end

    def correct_user
      @proposal = Proposal.find(params[:id])
      unless(current_user == @proposal.user || current_user.admin?)
        flash[:warning] = "You are neither the owner of this proposal nor the admin"
        redirect_to current_user
      end
    end

    def only_admin
      unless current_user.admin?
        flash[:warning] = "Only accessible to admins."
        redirect_to current_user
      end
    end
end