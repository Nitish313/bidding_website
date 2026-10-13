require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get signup_path
    assert_response :success
  end

  # destroy

  test "deleting a user redirects to login when logged out and deletes nothing" do
    assert_no_difference "User.count" do
      delete user_path(users(:freelancer))
    end
    assert_redirected_to login_path
  end

  test "a non-admin cannot delete another user" do
    log_in_as(users(:client))
    assert_no_difference "User.count" do
      delete user_path(users(:freelancer))
    end
    assert_redirected_to root_path
  end

  test "a non-admin cannot delete their own account through the admin action" do
    log_in_as(users(:client))
    assert_no_difference "User.count" do
      delete user_path(users(:client))
    end
    assert_redirected_to root_path
  end

  test "an admin deletes another user" do
    log_in_as(users(:admin))
    assert_difference "User.count", -1 do
      delete user_path(users(:inactive))
    end
    assert_redirected_to users_path
    assert_equal "User deleted!", flash[:success]
  end

  test "deleting a user also deletes their gigs and proposals" do
    log_in_as(users(:admin))
    gig_ids = users(:client).gigs.ids
    assert_not_empty gig_ids
    assert_difference "Gig.count", -gig_ids.size do
      delete user_path(users(:client))
    end
    assert_not Proposal.exists?(gig_id: gig_ids)
  end

  test "an admin cannot delete their own account" do
    log_in_as(users(:admin))
    assert_no_difference "User.count" do
      delete user_path(users(:admin))
    end
    assert_redirected_to users_path
    assert_equal "You can't delete your own account", flash[:danger]
  end

  test "an admin deleting a missing user raises not found" do
    log_in_as(users(:admin))
    assert_raises(ActiveRecord::RecordNotFound) { delete user_path(id: 0) }
  end
end
