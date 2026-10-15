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

  # posting and managing gigs

  def gig_params(overrides = {})
    { name: "Mobile app mockups", description: "Five screens.", budget: 300, location: "Remote",
      category_id: categories(:web_development).id, skill_list: "figma, ui design" }.merge(overrides)
  end

  test "posting a gig requires login" do
    get new_gig_path
    assert_redirected_to login_path
  end

  test "a freelancer cannot post a gig" do
    log_in_as(users(:freelancer))
    get new_gig_path
    assert_redirected_to gigs_path
    assert_no_difference "Gig.count" do
      post gigs_path, params: { gig: gig_params }
    end
  end

  test "a client posts a gig" do
    log_in_as(users(:client))
    get new_gig_path
    assert_response :success
    assert_difference "Gig.count", 1 do
      post gigs_path, params: { gig: gig_params }
    end
    gig = Gig.last
    assert_redirected_to gig_path(gig)
    assert_equal users(:client), gig.user
    assert_equal ["figma", "ui design"], gig.skills.pluck(:name).sort
  end

  test "an invalid gig is not posted" do
    log_in_as(users(:client))
    assert_no_difference "Gig.count" do
      post gigs_path, params: { gig: gig_params(name: "") }
    end
    assert_response :success
    assert_select "#error_explanation"
  end

  test "a gig page is public" do
    get gig_path(gigs(:landing_page))
    assert_response :success
    assert_select "body", text: /Build a landing page/
  end

  test "gigs can be listed by name" do
    get gigs_path(sort_by: "name")
    assert_response :success
    assert_operator response.body.index("Build a landing page"), :<, response.body.index("Write five blog posts")
  end

  test "the owner edits their gig" do
    log_in_as(users(:client))
    get edit_gig_path(gigs(:landing_page))
    assert_response :success
    patch gig_path(gigs(:landing_page)), params: { gig: { name: "Build a product page" } }
    assert_redirected_to gig_path(gigs(:landing_page))
    assert_equal "Build a product page", gigs(:landing_page).reload.name
  end

  test "an invalid gig edit is refused" do
    log_in_as(users(:client))
    patch gig_path(gigs(:landing_page)), params: { gig: { name: "" } }
    assert_response :success
    assert_select "#error_explanation"
    assert_equal "Build a landing page", gigs(:landing_page).reload.name
  end

  test "a user who does not own the gig cannot edit it" do
    log_in_as(users(:freelancer))
    get edit_gig_path(gigs(:landing_page))
    assert_redirected_to gig_path(gigs(:landing_page))
    patch gig_path(gigs(:landing_page)), params: { gig: { name: "Hacked" } }
    assert_equal "Build a landing page", gigs(:landing_page).reload.name
  end

  test "an admin edits any gig without becoming its owner" do
    log_in_as(users(:admin))
    patch gig_path(gigs(:landing_page)), params: { gig: { budget: 650 } }
    assert_redirected_to gig_path(gigs(:landing_page))
    gigs(:landing_page).reload
    assert_equal 650, gigs(:landing_page).budget
    assert_equal users(:client), gigs(:landing_page).user
  end

  test "the owner deletes a gig that has not been awarded" do
    log_in_as(users(:client))
    assert_difference "Gig.count", -1 do
      delete gig_path(gigs(:blog_posts))
    end
    assert_redirected_to gigs_path
  end

  test "a user who does not own the gig cannot delete it" do
    log_in_as(users(:freelancer))
    assert_no_difference "Gig.count" do
      delete gig_path(gigs(:blog_posts))
    end
  end

  test "an awarded gig cannot be deleted" do
    gigs(:landing_page).update!(awarded_proposal: proposals(:landing_page_bid).id)
    [users(:client), users(:admin)].each do |user|
      log_in_as(user)
      assert_no_difference "Gig.count" do
        delete gig_path(gigs(:landing_page))
      end
      assert_redirected_to gig_path(gigs(:landing_page))
      assert_equal "An awarded gig can't be deleted.", flash[:danger]
      delete logout_path
    end
  end

  test "a client sees their own gigs" do
    log_in_as(users(:client))
    get mygigs_path
    assert_response :success
    assert_select "body", text: /Build a landing page/
  end

  test "a freelancer has no gigs page" do
    log_in_as(users(:freelancer))
    get mygigs_path
    assert_redirected_to user_path(users(:freelancer))
  end

  test "gigs are listed newest first by default and oldest first on request" do
    gigs(:landing_page).update_columns(created_at: 2.days.ago)
    gigs(:blog_posts).update_columns(created_at: 1.day.ago)
    newer = "Write five blog posts"
    older = "Build a landing page"
    [gigs_path, gigs_path(sort_by: "newest")].each do |path|
      get path
      assert_operator response.body.index(newer), :<, response.body.index(older), path
    end
    get gigs_path(sort_by: "oldest")
    assert_operator response.body.index(older), :<, response.body.index(newer)
  end
end
