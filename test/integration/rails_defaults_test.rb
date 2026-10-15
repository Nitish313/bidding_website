require "test_helper"

class RailsDefaultsTest < ActionDispatch::IntegrationTest
  test "the app runs on the Rails 6.0 framework defaults" do
    assert_equal "6.0", Rails.application.config.loaded_config_version.to_s
    assert Rails.application.config.action_dispatch.use_cookies_with_metadata
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
