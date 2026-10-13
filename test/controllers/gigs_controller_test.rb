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
end
