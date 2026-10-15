require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "the home page lists activated freelancers to everyone" do
    get root_path
    assert_response :success
    assert_select "a", text: "Fiona Freelancer"
    assert_select "a", text: "Rita Rival"
  end

  test "the home page does not list clients or unactivated freelancers" do
    users(:rival).update_columns(activated: false)
    get root_path
    assert_select "a", text: "Carl Client", count: 0
    assert_select "a", text: "Rita Rival", count: 0
  end
end
