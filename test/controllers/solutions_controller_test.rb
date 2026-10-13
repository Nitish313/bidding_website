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
end
