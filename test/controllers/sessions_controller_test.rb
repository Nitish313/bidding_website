require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get login_path
    assert_response :success
  end

  test "logging in with the right password, ignoring email case" do
    post login_path, params: { session: { email: "FIONA@example.com", password: "test-password" } }
    assert_redirected_to user_path(users(:freelancer))
    assert_equal users(:freelancer).id, session[:user_id]
  end

  test "logging in with a wrong password shows an error and does not log in" do
    log_in_as(users(:freelancer), password: "wrong-password")
    assert_response :unprocessable_content
    assert_equal "Invalid login credentials!", flash[:danger]
    assert_nil session[:user_id]
  end

  test "logging in with an unknown email shows an error" do
    post login_path, params: { session: { email: "nobody@example.com", password: "test-password" } }
    assert_response :unprocessable_content
    assert_select "div", text: /Invalid login credentials!/
    assert_nil session[:user_id]
  end

  test "the login error does not carry over to the next page" do
    log_in_as(users(:freelancer), password: "wrong-password")
    get root_path
    assert_nil flash[:danger]
  end

  test "logging out when already logged out redirects home" do
    delete logout_path
    assert_redirected_to root_path
  end
end
