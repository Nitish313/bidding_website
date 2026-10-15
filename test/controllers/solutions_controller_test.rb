require "test_helper"

class SolutionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @gig = gigs(:landing_page)
    @proposal = proposals(:landing_page_bid)
    @freelancer = users(:freelancer)
  end

  def award(proposal)
    proposal.gig.update_columns(awarded_proposal: proposal.id)
  end

  def submit_solution(proposal, attachment: fixture_file_upload("files/solution.txt", "text/plain"))
    post proposal_solutions_path(proposal), params: { solution: { name: "Delivery", attachment_1: attachment } }
  end

  test "my_solutions redirects to login when logged out" do
    get my_solutions_path
    assert_redirected_to login_path
  end

  # create

  test "the awarded freelancer can submit a solution" do
    award(@proposal)
    log_in_as(@freelancer)
    assert_difference "@proposal.solutions.count", 1 do
      submit_solution(@proposal)
    end
    assert_redirected_to proposal_path(@proposal)
    assert_equal @gig, @proposal.solutions.last.gig
  end

  test "submitting is refused when logged out" do
    award(@proposal)
    assert_no_difference "Solution.count" do
      submit_solution(@proposal)
    end
    assert_redirected_to login_path
  end

  test "submitting is refused for a client" do
    award(@proposal)
    log_in_as(users(:client))
    assert_no_difference "Solution.count" do
      submit_solution(@proposal)
    end
  end

  test "submitting is refused for a freelancer who does not own the proposal" do
    award(@proposal)
    log_in_as(users(:rival))
    assert_no_difference "Solution.count" do
      submit_solution(@proposal)
    end
    assert_redirected_to user_path(users(:rival))
  end

  test "submitting is refused while the gig has not been awarded" do
    log_in_as(@freelancer)
    assert_no_difference "Solution.count" do
      submit_solution(@proposal)
    end
    assert_redirected_to proposal_path(@proposal)
  end

  test "submitting is refused when the gig was awarded to another proposal" do
    award(proposals(:rival_bid))
    log_in_as(@freelancer)
    assert_no_difference "Solution.count" do
      submit_solution(@proposal)
    end
    assert_redirected_to proposal_path(@proposal)
  end

  test "submitting without the required attachment saves nothing and explains why" do
    award(@proposal)
    log_in_as(@freelancer)
    assert_no_difference "Solution.count" do
      submit_solution(@proposal, attachment: nil)
    end
    assert_redirected_to proposal_path(@proposal)
    assert_match "Attachment 1", flash[:danger]
  end

  test "submitting to a missing proposal raises not found" do
    log_in_as(@freelancer)
    assert_raises(ActiveRecord::RecordNotFound) do
      post proposal_solutions_path(proposal_id: 0), params: { solution: { name: "Delivery" } }
    end
  end

  # viewing and deleting

  def solution
    solutions(:landing_page_delivery)
  end

  test "the solutions list requires login" do
    get gig_solutions_path(@gig)
    assert_redirected_to login_path
  end

  test "the gig owner, the proposal owner and an admin can see the solutions" do
    [users(:client), @freelancer, users(:admin)].each do |user|
      log_in_as(user)
      get gig_solutions_path(@gig)
      assert_response :success, user.name
      delete logout_path
    end
  end

  test "other users cannot see the solutions" do
    log_in_as(users(:rival))
    get gig_solutions_path(@gig)
    assert_redirected_to user_path(users(:rival))
    assert_equal "Only accessible to the owners.", flash[:warning]
  end

  test "deleting a solution requires login" do
    assert_no_difference "Solution.count" do
      delete gig_solution_path(@gig, solution)
    end
    assert_redirected_to login_path
  end

  test "the proposal owner, the gig owner and an admin can delete a solution" do
    [@freelancer, users(:client), users(:admin)].each do |user|
      id = Solution.create!(name: "Extra", attachment_1: fixture_file_upload("files/solution.txt", "text/plain"),
                            gig: @gig, proposal: @proposal).id
      log_in_as(user)
      assert_difference "Solution.count", -1, user.name do
        delete gig_solution_path(@gig, id)
      end
      assert_redirected_to gig_solutions_path(@gig)
      delete logout_path
    end
  end

  test "other users cannot delete a solution" do
    log_in_as(users(:rival))
    assert_no_difference "Solution.count" do
      delete gig_solution_path(@gig, solution)
    end
    assert_redirected_to user_path(users(:rival))
    assert_equal "Only owners can delete their solutions.", flash[:warning]
  end

  test "a freelancer sees the solutions they submitted" do
    log_in_as(@freelancer)
    get my_solutions_path
    assert_response :success
    assert_select "body", text: /Landing page delivery/
  end
end
