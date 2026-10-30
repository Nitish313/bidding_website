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

  # profiles

  test "an activated user's profile is public" do
    get user_path(users(:freelancer))
    assert_response :success
    assert_select "body", text: /Fiona Freelancer/
  end

  test "an unactivated user's profile redirects to the home page" do
    get user_path(users(:inactive))
    assert_redirected_to root_path
  end

  test "the user list is public" do
    get users_path
    assert_response :success
    assert_select "a", text: "Carl Client"
  end

  test "editing a profile requires login" do
    get edit_user_path(users(:client))
    assert_redirected_to login_path
  end

  test "a user edits their own profile" do
    log_in_as(users(:client))
    get edit_user_path(users(:client))
    assert_response :success
    patch user_path(users(:client)), params: { user: { name: "Carl Customer" } }
    assert_redirected_to user_path(users(:client))
    assert_equal "Profile updated", flash[:success]
    assert_equal "Carl Customer", users(:client).reload.name
  end

  test "an invalid profile update is refused" do
    log_in_as(users(:client))
    patch user_path(users(:client)), params: { user: { name: "" } }
    assert_response :unprocessable_entity
    assert_select "#error_explanation"
    assert_equal "Carl Client", users(:client).reload.name
  end

  test "a user cannot edit someone else's profile" do
    log_in_as(users(:client))
    get edit_user_path(users(:freelancer))
    assert_redirected_to root_path
    patch user_path(users(:freelancer)), params: { user: { name: "Hacked" } }
    assert_redirected_to root_path
    assert_equal "Fiona Freelancer", users(:freelancer).reload.name
  end

  test "an admin edits another user's profile" do
    log_in_as(users(:admin))
    patch user_path(users(:client)), params: { user: { name: "Carl Corrected" } }
    assert_redirected_to user_path(users(:client))
    assert_equal "Carl Corrected", users(:client).reload.name
  end

  test "a user cannot make themselves an admin or activate themselves" do
    log_in_as(users(:client))
    patch user_path(users(:client)), params: { user: { name: "Carl", admin: true, activated: false } }
    users(:client).reload
    assert_not users(:client).admin?
    assert_predicate users(:client), :activated?
  end
end
