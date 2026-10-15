require "test_helper"

class RailsDefaultsTest < ActionDispatch::IntegrationTest
  # Keys as Rails derived them before 7.0 (SHA1 key generator), to build cookies
  # that browsers already hold from earlier versions of the app.
  def legacy_key(salt, length = 64)
    generator = ActiveSupport::KeyGenerator.new(
      Rails.application.secret_key_base, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1
    )
    generator.generate_key(salt, length)
  end

  def legacy_signed(value)
    secret = legacy_key(Rails.application.config.action_dispatch.signed_cookie_salt)
    ActiveSupport::MessageVerifier.new(secret, digest: "SHA1", serializer: JSON).generate(value)
  end

  def legacy_encrypted(value, purpose:)
    config = Rails.application.config.action_dispatch
    secret = legacy_key(config.authenticated_encrypted_cookie_salt, ActiveSupport::MessageEncryptor.key_len("aes-256-gcm"))
    ActiveSupport::MessageEncryptor.new(secret, cipher: "aes-256-gcm", serializer: ActiveSupport::MessageEncryptor::NullSerializer)
                                   .encrypt_and_sign(value.to_json, purpose: purpose)
  end

  test "the app runs on the Rails 7.0 framework defaults" do
    assert_equal "7.0", Rails.application.config.loaded_config_version.to_s
    assert_equal OpenSSL::Digest::SHA256, Rails.application.config.active_support.key_generator_hash_digest_class
  end

  test "responses carry the Rails 7.0 security headers" do
    get root_path
    assert_equal "0", response.headers["X-XSS-Protection"]
    assert_equal "strict-origin-when-cross-origin", response.headers["Referrer-Policy"]
  end

  test "forms no longer add the hidden utf8 field" do
    get login_path
    assert_select "input[name=utf8]", count: 0
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

  test "deleting a gig never redirects to another site" do
    log_in_as(users(:client))
    delete gig_path(gigs(:blog_posts)), headers: { "HTTP_REFERER" => "https://evil.example.com/phish" }
    assert_redirected_to gigs_path
  end

  test "a session cookie from before the 7.0 key change keeps the user logged in" do
    session_data = { "session_id" => SecureRandom.hex(16), "user_id" => users(:client).id }
    cookies[:_bidding_website_session] = legacy_encrypted(session_data, purpose: "cookie._bidding_website_session")
    get mygigs_path
    assert_response :success
  end

  test "a remember-me cookie from before the 7.0 key change still logs the user in" do
    client = users(:client)
    client.remember
    cookies[:user_id] = legacy_signed(client.id)
    cookies[:remember_token] = client.remember_token
    get mygigs_path
    assert_response :success
  end
end
