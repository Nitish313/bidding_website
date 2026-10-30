require "test_helper"

class SignupAndActivationTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
  end

  def signup_params(overrides = {})
    { name: "Nina New", email: "Nina@Example.com", password: "s3cret-pass", password_confirmation: "s3cret-pass",
      role: "Client", industry: "Retail",
      profile_picture: fixture_file_upload("avatar.png", "image/png") }.merge(overrides)
  end

  def sign_up(overrides = {})
    post signup_path, params: { user: signup_params(overrides) }
  end

  def activation_link_from(mail)
    mail.text_part.decoded[%r{http://\S+/account_activations/\S+}]
  end

  test "a valid signup creates an unactivated user and emails an activation link" do
    assert_difference "User.count", 1 do
      sign_up
    end
    user = User.last
    assert_equal "nina@example.com", user.email
    assert_not user.activated?
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries.last
    assert_equal [user.email], mail.to
    assert_not_nil activation_link_from(mail)
    assert_redirected_to root_url
    assert_equal "Please check your email to activate your account", flash[:info]
  end

  test "a freelancer must give education and experience" do
    assert_no_difference "User.count" do
      sign_up(role: "Freelancer")
    end
    assert_response :unprocessable_entity
    assert_select "#error_explanation", text: /Education can't be blank/
  end

  test "an invalid signup is refused and sends no email" do
    [{ name: "" }, { email: "not-an-email" }, { password_confirmation: "different" },
     { profile_picture: nil }, { email: users(:client).email.upcase }].each do |bad|
      assert_no_difference "User.count", bad.inspect do
        sign_up(bad)
      end
      assert_response :unprocessable_entity
      assert_select "#error_explanation"
    end
    assert_empty ActionMailer::Base.deliveries
  end

  test "a new user cannot log in before activating" do
    sign_up
    log_in_as(User.last, password: "s3cret-pass")
    assert_nil session[:user_id]
  end

  test "the activation link activates and logs in the user" do
    sign_up
    user = User.last
    get activation_link_from(ActionMailer::Base.deliveries.last)
    assert_predicate user.reload, :activated?
    assert_not_nil user.activated_at
    assert_redirected_to user_path(user)
    assert_equal user.id, session[:user_id]
  end

  test "an activation link with the wrong token or email is refused" do
    sign_up
    user = User.last
    get edit_account_activation_path("wrong-token", email: user.email)
    assert_redirected_to root_path
    assert_equal "Invalid Activation Link", flash[:danger]
    link = activation_link_from(ActionMailer::Base.deliveries.last)
    get link.sub("nina%40example.com", "someone%40example.com")
    assert_redirected_to root_path
    assert_not user.reload.activated?
  end

  test "an activation link cannot be used twice" do
    sign_up
    link = activation_link_from(ActionMailer::Base.deliveries.last)
    get link
    delete logout_path
    get link
    assert_redirected_to root_path
    assert_nil session[:user_id]
  end
end
