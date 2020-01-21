class ProposalsController < ApplicationController
  before_action :logged_in_user, only: [:create]
  def create
    @gig = Gig.find(params[:gig_id])
    @proposal = @gig.proposals.build(proposal_params)
    @proposal.user = current_user
    @proposal.save
    flash[:success] = "Proposal successfully submitted."
    redirect_to @proposal.gig
  end

  def proposal_params
    params.require(:proposal).permit(:bid, :description)
  end
end