class SolutionsController < ApplicationController
  before_action :logged_in_user, only: [:index, :create, :destroy, :my_solutions]
  before_action :only_freelancers, only: [:create]
  before_action :correct_user, only: [:destroy]
  before_action :only_for_owners, only: [:index]

  def index
  end

  def create
    @proposal = Proposal.find(params[:proposal_id])
    @solution = @proposal.solutions.build(solution_params)
    @solution.gig = @proposal.gig
    if @solution.save
      flash[:success] = "Your solution is successfully submitted."
    else
      flash[:danger] = @solution.errors.full_messages.to_sentence
    end 
    redirect_to @proposal
  end

  def destroy
    @solution = Solution.find(params[:id])
    @solution.destroy
    flash[:success] = "This solution is deleted."
    redirect_to gig_solutions_path(gig_id: params[:gig_id])
  end

  def my_solutions
    @proposals = Proposal.where(user_id: current_user.id)
  end

  private

    def solution_params
      params.require(:solution).permit(:name, :attachment_1, :attachment_2, :attachment_3)
    end

    def only_freelancers
      unless current_user.role == "Freelancer"
        flash[:warning] = "Only accessible to the freelancers."
        redirect_to current_user
      end
    end

    def correct_user
      @solution = Solution.find(params[:id])
      unless (current_user.admin?) || (current_user.role == "Freelancer" && @solution.proposal.user == current_user) || (current_user.role == "Client" && @solution.gig.user == current_user)
        flash[:warning] = "Only owners can delete their solutions."
        redirect_to current_user
      end
    end

    def only_for_owners
      @solutions = Solution.where(gig_id: params[:gig_id])
      if @solutions.any?
        unless current_user.admin? || @solutions.first.gig.user == current_user || @solutions.first.proposal.user == current_user
          flash[:warning] = "Only accessible to the owners."
          redirect_to current_user
        end
      end
    end
end
