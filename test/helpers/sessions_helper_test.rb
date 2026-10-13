require 'test_helper'

class SessionsHelperTest < ActionView::TestCase
  def setup
    @user = users(:freelancer)
  end

  test "current_user is nil with no session and no cookies" do
    assert_nil current_user
  end

  test "current_user uses the session when it is set" do
    log_in(users(:client))
    assert_equal users(:client), current_user
  end

  test "current_user logs in a remembered user when the session is empty" do
    remember(@user)
    assert_nil session[:user_id]
    assert_equal @user, current_user
    assert_equal @user.id, session[:user_id]
  end

  test "current_user is nil when the remember digest does not match" do
    remember(@user)
    @user.update_attribute(:remember_digest, User.digest(User.new_token))
    assert_nil current_user
  end

  test "current_user is nil when the remember token cookie is missing" do
    remember(@user)
    cookies.delete(:remember_token)
    assert_nil current_user
  end

  test "current_user is nil when the user_id cookie is not signed" do
    remember(@user)
    cookies[:user_id] = @user.id.to_s
    assert_nil current_user
  end

  test "current_user is nil when the remembered user no longer exists" do
    remember(@user)
    @user.destroy
    assert_nil current_user
  end

  test "current_user is nil after the user is forgotten" do
    remember(@user)
    forget(@user)
    assert_nil current_user
  end
end
