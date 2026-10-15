require "test_helper"

class RailsDefaultsTest < ActionDispatch::IntegrationTest
  test "the app runs on the Rails 6.1 framework defaults" do
    assert_equal "6.1", Rails.application.config.loaded_config_version.to_s
    assert Rails.application.config.action_dispatch.use_cookies_with_metadata
  end

  test "login and remember-me cookies are sent with SameSite=Lax" do
    log_in_as(users(:client), remember_me: "1")
    set_cookies = Array(response.headers["Set-Cookie"]).join("\n").split("\n")
    %w[_bidding_website_session user_id remember_token].each do |name|
      cookie = set_cookies.find { |line| line.start_with?("#{name}=") }
      assert cookie, "no #{name} cookie set"
      assert_match(/samesite=lax/i, cookie, name)
    end
  end

  test "forms no longer add the hidden utf8 field" do
    get login_path
    assert_select "input[name=utf8]", count: 0
  end

  test "a remember-me cookie written before the switch still logs the user in" do
    client = users(:client)
    client.remember
    config = Rails.application.config.action_dispatch
    secret = Rails.application.key_generator.generate_key(config.signed_cookie_salt)
    # The format Rails 5.2 wrote: signed with SHA1, JSON-serialised, no purpose metadata.
    legacy_signed_id = ActiveSupport::MessageVerifier.new(secret, digest: "SHA1", serializer: JSON).generate(client.id)
    cookies[:user_id] = legacy_signed_id
    cookies[:remember_token] = client.remember_token

    get mygigs_path
    assert_response :success
  end
end
