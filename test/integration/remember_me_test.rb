require 'test_helper'

class RememberMeTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:freelancer)
  end

  test "login with remember me stores a remember token" do
    log_in_as(@user, remember_me: '1')
    assert_not cookies[:remember_token].blank?
    assert @user.reload.authenticated?(:remember, cookies[:remember_token])
  end

  test "login without remember me stores no remember token" do
    log_in_as(@user, remember_me: '1')
    log_in_as(@user, remember_me: '0')
    assert cookies[:remember_token].blank?
    assert_nil @user.reload.remember_digest
  end

  test "logout forgets the remembered user" do
    log_in_as(@user, remember_me: '1')
    delete logout_path
    assert_redirected_to root_path
    assert cookies[:remember_token].blank?
    assert_nil @user.reload.remember_digest
  end
end
