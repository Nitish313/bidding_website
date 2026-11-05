require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_password_reset_path
    assert_response :success
  end

  test "edit with an invalid token redirects to root" do
    get edit_password_reset_path("invalid-token", email: users(:freelancer).email)
    assert_redirected_to root_url
  end
end
