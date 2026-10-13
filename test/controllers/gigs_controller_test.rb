require 'test_helper'

class GigsControllerTest < ActionDispatch::IntegrationTest
  test "search by keyword lists only matching gigs" do
    get search_gigs_path, params: { search: "landing" }
    assert_response :success
    assert_select "a", text: gigs(:landing_page).name
    assert_select "a", text: gigs(:blog_posts).name, count: 0
  end

  test "search by category lists only gigs in that category" do
    get search_gigs_path, params: { category: categories(:writing).id }
    assert_response :success
    assert_select "a", text: gigs(:blog_posts).name
    assert_select "a", text: gigs(:landing_page).name, count: 0
  end

  test "search with no criteria lists all gigs" do
    get search_gigs_path
    assert_response :success
    assert_select "a", text: gigs(:landing_page).name
    assert_select "a", text: gigs(:blog_posts).name
  end

  test "search treats a wildcard keyword literally" do
    get search_gigs_path, params: { search: "%" }
    assert_response :success
    assert_select "a", text: gigs(:landing_page).name, count: 0
    assert_select "a", text: gigs(:blog_posts).name, count: 0
  end

  test "search ignores parameters other than category and search" do
    get search_gigs_path, params: { search: "landing", user_id: users(:client).id }
    assert_response :success
    assert_select "a", text: gigs(:landing_page).name
  end

  # awarding

  def award(gig, proposal_id)
    patch gig_path(gig), params: { gig: { awarded_proposal: proposal_id } }
  end

  test "the gig owner awards one of the gig's proposals" do
    log_in_as(users(:client))
    award(gigs(:landing_page), proposals(:landing_page_bid).id)
    assert_redirected_to gig_path(gigs(:landing_page))
    assert_equal proposals(:landing_page_bid).id, gigs(:landing_page).reload.awarded_proposal
  end

  test "the gig owner cannot award a proposal from another gig" do
    other = Proposal.create!(name: "Bid", bid: 100, description: "Offer",
                             gig: gigs(:blog_posts), user: users(:freelancer))
    log_in_as(users(:client))
    award(gigs(:landing_page), other.id)
    assert_response :success
    assert_select "#error_explanation"
    assert_nil gigs(:landing_page).reload.awarded_proposal
  end

  test "a user who does not own the gig cannot award it" do
    log_in_as(users(:freelancer))
    award(gigs(:landing_page), proposals(:landing_page_bid).id)
    assert_redirected_to gig_path(gigs(:landing_page))
    assert_nil gigs(:landing_page).reload.awarded_proposal
  end

  test "awarding requires login" do
    award(gigs(:landing_page), proposals(:landing_page_bid).id)
    assert_redirected_to login_path
    assert_nil gigs(:landing_page).reload.awarded_proposal
  end
end
