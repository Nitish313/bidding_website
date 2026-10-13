require "test_helper"

class UserActivationTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
    @client = users(:client)
    @freelancer = users(:freelancer)
    @inactive = users(:inactive)
  end

  # deactivate

  test "deactivate redirects to login when logged out and changes nothing" do
    post deactivate_user_path(@freelancer)
    assert_redirected_to login_path
    assert_predicate @freelancer.reload, :activated?
  end

  test "deactivate is refused for a non-admin acting on another user" do
    log_in_as(@client)
    post deactivate_user_path(@freelancer)
    assert_redirected_to root_path
    assert_predicate @freelancer.reload, :activated?
  end

  test "deactivate is refused for a non-admin acting on themselves" do
    log_in_as(@client)
    post deactivate_user_path(@client)
    assert_redirected_to root_path
    assert_predicate @client.reload, :activated?
  end

  test "deactivate refuses a non-admin before looking up the user" do
    log_in_as(@client)
    post deactivate_user_path(id: 0)
    assert_redirected_to root_path
  end

  test "admin deactivates another user" do
    log_in_as(@admin)
    post deactivate_user_path(@freelancer)
    assert_redirected_to users_path
    assert_equal "User deactivated", flash[:success]
    assert_not @freelancer.reload.activated?
  end

  test "admin deactivates a user whose profile does not pass validation" do
    @freelancer.update_columns(education: nil)
    assert_not @freelancer.reload.valid?
    log_in_as(@admin)
    post deactivate_user_path(@freelancer)
    assert_not @freelancer.reload.activated?
  end

  test "admin deactivating an already deactivated user keeps them deactivated" do
    log_in_as(@admin)
    post deactivate_user_path(@inactive)
    assert_redirected_to users_path
    assert_not @inactive.reload.activated?
  end

  test "admin cannot deactivate their own account" do
    log_in_as(@admin)
    post deactivate_user_path(@admin)
    assert_redirected_to users_path
    assert_equal "You can't deactivate your own account", flash[:danger]
    assert_predicate @admin.reload, :activated?
  end

  test "admin deactivating a missing user raises not found" do
    log_in_as(@admin)
    assert_raises(ActiveRecord::RecordNotFound) { post deactivate_user_path(id: 0) }
  end

  test "deactivate is not reachable with GET" do
    assert_raises(ActionController::RoutingError) { get "/users/#{@freelancer.id}/deactivate" }
  end

  # activate

  test "activate redirects to login when logged out and changes nothing" do
    post activate_user_path(@inactive)
    assert_redirected_to login_path
    assert_not @inactive.reload.activated?
  end

  test "activate is refused for a non-admin" do
    log_in_as(@client)
    post activate_user_path(@inactive)
    assert_redirected_to root_path
    assert_not @inactive.reload.activated?
  end

  test "admin activates a deactivated user and records when" do
    log_in_as(@admin)
    post activate_user_path(@inactive)
    assert_redirected_to users_path
    assert_equal "User activated", flash[:success]
    @inactive.reload
    assert_predicate @inactive, :activated?
    assert_not_nil @inactive.activated_at
  end

  test "admin activating a missing user raises not found" do
    log_in_as(@admin)
    assert_raises(ActiveRecord::RecordNotFound) { post activate_user_path(id: 0) }
  end

  test "activate is not reachable with GET" do
    assert_raises(ActionController::RoutingError) { get "/users/#{@inactive.id}/activate" }
  end

  # effects of deactivation

  test "a deactivated user cannot log in" do
    log_in_as(@inactive)
    assert_redirected_to root_url
    assert_nil session[:user_id]
  end

  test "a reactivated user can log in again" do
    log_in_as(@admin)
    post activate_user_path(@inactive)
    delete logout_path
    log_in_as(@inactive)
    assert_redirected_to user_path(@inactive)
  end

  test "a logged-in user loses access as soon as they are deactivated" do
    log_in_as(@client)
    get mygigs_path
    assert_response :success
    @client.update_columns(activated: false)
    get mygigs_path
    assert_redirected_to login_path
  end
end
