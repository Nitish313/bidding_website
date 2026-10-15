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

  # bidding

  def bid_on(gig, bid: 180)
    post gig_proposals_path(gig), params: { proposal: { name: "My bid", bid: bid, description: "I can do it." } }
  end

  test "a freelancer bids on a gig and the client is notified" do
    log_in_as(users(:freelancer))
    assert_difference "Proposal.count", 1 do
      assert_difference "Notification.where(action: 'proposed').count", 1 do
        bid_on(gigs(:blog_posts))
      end
    end
    assert_redirected_to gig_path(gigs(:blog_posts))
    assert_equal users(:freelancer), Proposal.last.user
    assert_equal users(:client).id, Notification.last.receiver_id
  end

  test "bidding requires login" do
    assert_no_difference "Proposal.count" do
      bid_on(gigs(:blog_posts))
    end
    assert_redirected_to login_path
  end

  test "a client cannot bid" do
    log_in_as(users(:client))
    assert_no_difference "Proposal.count" do
      bid_on(gigs(:blog_posts))
    end
  end

  test "an incomplete bid is refused" do
    log_in_as(users(:freelancer))
    assert_no_difference "Proposal.count" do
      bid_on(gigs(:blog_posts), bid: "")
    end
    assert_redirected_to gig_path(gigs(:blog_posts))
    assert_match "Bid can't be blank", flash[:danger]
  end

  test "a freelancer can bid only once per gig" do
    log_in_as(users(:freelancer))
    assert_no_difference "Proposal.count" do
      bid_on(gigs(:landing_page))
    end
    assert_redirected_to gig_path(gigs(:landing_page))
    assert_equal "You have already submitted a proposal for this gig.", flash[:danger]
  end

  test "a closed gig takes no bids" do
    gigs(:blog_posts).update_columns(open: false)
    log_in_as(users(:freelancer))
    assert_no_difference "Proposal.count" do
      bid_on(gigs(:blog_posts))
    end
    assert_redirected_to gig_path(gigs(:blog_posts))
    assert_equal "This gig is closed to new proposals.", flash[:danger]
  end

  test "a freelancer sees their own proposals" do
    log_in_as(users(:freelancer))
    get myproposals_path
    assert_response :success
    assert_select "body", text: /Build a landing page/
  end

  # admin list and proposal page

  test "an admin sees the list of all proposals" do
    log_in_as(users(:admin))
    get proposals_path
    assert_response :success
    assert_select "body", text: /Landing page proposal/
  end

  test "the list of all proposals is refused to non-admins" do
    log_in_as(users(:client))
    get proposals_path
    assert_redirected_to user_path(users(:client))
    assert_equal "Only accessible to admins.", flash[:warning]
  end

  test "a proposal page is public" do
    get proposal_path(@proposal)
    assert_response :success
    assert_select "h3", text: /Proposal for Build a landing page/
    assert_select "p", text: "Responsive page delivered within a week."
    assert_select "form", count: 0
  end

  test "the awarded freelancer sees the solution upload form on their proposal" do
    gigs(:landing_page).update_columns(awarded_proposal: @proposal.id)
    log_in_as(users(:freelancer))
    get proposal_path(@proposal)
    assert_select "form[action=?]", proposal_solutions_path(@proposal)
  end

  test "a missing proposal raises not found" do
    assert_raises(ActiveRecord::RecordNotFound) { get proposal_path(id: 0) }
  end
end
