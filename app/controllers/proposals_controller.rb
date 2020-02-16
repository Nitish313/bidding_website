class ProposalsController < ApplicationController
  before_action :logged_in_user, only: [:create, :myproposals]
  before_action :only_freelancers, only: [:create, :myproposals]

  def create
    @gig = Gig.find(params[:gig_id])
    @proposal = @gig.proposals.build(proposal_params)
    @proposal.user = current_user
    @proposal.save
    flash[:success] = "Proposal successfully submitted."
    redirect_to @proposal.gig
  end

  def myproposals
    @proposals = Proposal.where(user_id: current_user.id).order(created_at: :desc)
  end

  def show
    @proposal = Proposal.find(params[:id])
    @gig = @proposal.gig
  end

  private
    def proposal_params
      params.require(:proposal).permit(:bid, :description)
    end

    def only_freelancers
      unless current_user.role == "Freelancer"
        flash[:warning] = "You need to be the owner as well as a freelancer to view this page."
        redirect_to current_user
      end
    end
end