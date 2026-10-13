require "test_helper"

class ProposalTest < ActiveSupport::TestCase
  def build_proposal(gig:, user:)
    Proposal.new(name: "Bid", bid: 100, description: "Offer", gig: gig, user: user)
  end

  test "a freelancer can bid on an open gig" do
    assert_predicate build_proposal(gig: gigs(:blog_posts), user: users(:freelancer)), :valid?
  end

  test "a second bid by the same freelancer on the same gig is invalid" do
    proposal = build_proposal(gig: gigs(:landing_page), user: users(:freelancer))
    assert_not proposal.valid?
    assert_includes proposal.errors[:base], "You have already submitted a proposal for this gig."
  end

  test "another freelancer can still bid on the same gig" do
    gigs(:landing_page).proposals.where(user: users(:rival)).delete_all
    assert_predicate build_proposal(gig: gigs(:landing_page), user: users(:rival)), :valid?
  end

  test "a bid on a closed gig is invalid" do
    gigs(:blog_posts).update_columns(open: false)
    proposal = build_proposal(gig: gigs(:blog_posts), user: users(:freelancer))
    assert_not proposal.valid?
    assert_includes proposal.errors[:base], "This gig is closed to new proposals."
  end

  test "existing proposals stay editable after the gig closes" do
    gigs(:landing_page).update_columns(open: false)
    proposal = proposals(:landing_page_bid)
    assert proposal.update(bid: 420)
  end
end
