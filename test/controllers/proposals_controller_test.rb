require "test_helper"

class ProposalsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @proposal = proposals(:landing_page_bid)
  end

  test "deleting a proposal redirects to login when logged out and deletes nothing" do
    assert_no_difference "Proposal.count" do
      delete proposal_path(@proposal)
    end
    assert_redirected_to login_path
  end

  test "deleting someone else's proposal is refused" do
    log_in_as(users(:client))
    assert_no_difference "Proposal.count" do
      delete proposal_path(@proposal)
    end
    assert_redirected_to user_path(users(:client))
  end

  test "the owner deletes their proposal" do
    log_in_as(users(:freelancer))
    assert_difference "Proposal.count", -1 do
      delete proposal_path(@proposal)
    end
    assert_redirected_to myproposals_path
  end

  test "an admin deletes any proposal" do
    log_in_as(users(:admin))
    assert_difference "Proposal.count", -1 do
      delete proposal_path(@proposal)
    end
    assert_redirected_to proposals_path
  end

  test "the admin proposal list requires login" do
    get proposals_path
    assert_redirected_to login_path
  end

  test "my proposals requires login" do
    get myproposals_path
    assert_redirected_to login_path
  end
end
