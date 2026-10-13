require "test_helper"

class PasswordResetTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:freelancer)
  end

  def request_reset(email)
    post password_resets_path, params: { password_reset: { email: email } }
  end

  def reset_token
    ActionMailer::Base.deliveries.last.text_part.decoded[%r{/password_resets/([^/]+)/edit}, 1]
  end

  def submit_new_password(token, password, confirmation = password, email: @user.email)
    patch password_reset_path(token), params: { email: email, user: { password: password, password_confirmation: confirmation } }
  end

  test "requesting a reset for an unknown email sends nothing" do
    request_reset("nobody@example.com")
    assert_response :success
    assert_equal "Email address not found", flash[:danger]
    assert_empty ActionMailer::Base.deliveries
  end

  test "requesting a reset emails a link, ignoring email case" do
    request_reset(@user.email.upcase)
    assert_redirected_to root_path
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal [@user.email], ActionMailer::Base.deliveries.last.to
    assert_not_nil @user.reload.reset_digest
    assert_not_nil reset_token
  end

  test "the reset link shows the new password form" do
    request_reset(@user.email)
    get edit_password_reset_path(reset_token, email: @user.email)
    assert_response :success
    assert_select "input[name=email][type=hidden][value=?]", @user.email
    assert_select "input[name='user[password]']"
  end

  test "the reset link is refused with the wrong email or for an inactive user" do
    request_reset(@user.email)
    token = reset_token
    get edit_password_reset_path(token, email: "someone@example.com")
    assert_redirected_to root_url
    @user.update_columns(activated: false)
    get edit_password_reset_path(token, email: @user.email)
    assert_redirected_to root_url
  end

  test "an expired reset link is refused" do
    request_reset(@user.email)
    @user.update_columns(reset_sent_at: 3.hours.ago)
    get edit_password_reset_path(reset_token, email: @user.email)
    assert_redirected_to new_password_reset_url
    assert_equal "Password reset has expired", flash[:danger]
  end

  test "an empty or mismatched new password is refused" do
    request_reset(@user.email)
    token = reset_token
    submit_new_password(token, "")
    assert_response :success
    assert_select "#error_explanation", text: /Password can't be empty/
    submit_new_password(token, "new-pass-1", "new-pass-2")
    assert_response :success
    assert_select "#error_explanation"
    assert @user.reload.authenticate("test-password")
  end

  test "a valid new password logs the user in and the link stops working" do
    request_reset(@user.email)
    token = reset_token
    submit_new_password(token, "brand-new-pass")
    assert_redirected_to user_path(@user)
    assert_equal "Password has been reset", flash[:success]
    assert_equal @user.id, session[:user_id]
    assert_nil @user.reload.reset_digest
    assert @user.authenticate("brand-new-pass")
    delete logout_path
    submit_new_password(token, "another-pass")
    assert_redirected_to root_url
    assert @user.reload.authenticate("brand-new-pass")
  end
end
