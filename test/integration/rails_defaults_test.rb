require "test_helper"

class RailsDefaultsTest < ActionDispatch::IntegrationTest
  # Cookies that browsers already hold from earlier versions of the app.
  # Before Rails 7.0 keys came from a SHA1 key generator; from 7.0 they come from
  # SHA256. Before the 7.1 defaults, metadata used the old envelope format.
  def key(salt, digest:, length: 64)
    generator = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base, iterations: 1000,
                                                                                   hash_digest_class: digest)
    generator.generate_key(salt, length)
  end

  def with_pre_7_1_metadata
    previous = ActiveSupport::Messages::Metadata.use_message_serializer_for_metadata
    ActiveSupport::Messages::Metadata.use_message_serializer_for_metadata = false
    yield
  ensure
    ActiveSupport::Messages::Metadata.use_message_serializer_for_metadata = previous
  end

  def old_signed(value, digest:)
    secret = key(Rails.application.config.action_dispatch.signed_cookie_salt, digest: digest)
    with_pre_7_1_metadata { ActiveSupport::MessageVerifier.new(secret, digest: "SHA1", serializer: JSON).generate(value) }
  end

  def old_encrypted(value, purpose:, digest:)
    salt = Rails.application.config.action_dispatch.authenticated_encrypted_cookie_salt
    secret = key(salt, digest: digest, length: ActiveSupport::MessageEncryptor.key_len("aes-256-gcm"))
    encryptor = ActiveSupport::MessageEncryptor.new(secret, cipher: "aes-256-gcm",
                                                            serializer: ActiveSupport::MessageEncryptor::NullSerializer)
    with_pre_7_1_metadata { encryptor.encrypt_and_sign(value.to_json, purpose: purpose) }
  end

  def assert_old_cookies_log_in(digest)
    client = users(:client)
    session_data = { "session_id" => SecureRandom.hex(16), "user_id" => client.id }
    cookies[:_bidding_website_session] = old_encrypted(session_data, purpose: "cookie._bidding_website_session",
                                                                     digest: digest)
    get mygigs_path
    assert_response :success, "session cookie (#{digest.name})"

    cookies.delete(:_bidding_website_session)
    client.remember
    cookies[:user_id] = old_signed(client.id, digest: digest)
    cookies[:remember_token] = client.remember_token
    get mygigs_path
    assert_response :success, "remember-me cookie (#{digest.name})"
  end

  test "the app runs on the Rails 7.1 framework defaults" do
    assert_equal "7.1", Rails.application.config.loaded_config_version.to_s
    assert_equal OpenSSL::Digest::SHA256, Rails.application.config.active_support.key_generator_hash_digest_class
    assert Rails.application.config.active_support.use_message_serializer_for_metadata
  end

  test "responses carry the current security headers" do
    get root_path
    assert_equal "0", response.headers["X-XSS-Protection"]
    assert_equal "strict-origin-when-cross-origin", response.headers["Referrer-Policy"]
    assert_nil response.headers["X-Download-Options"]
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

  test "cookies from before Rails 7.0 still log the user in" do
    assert_old_cookies_log_in(OpenSSL::Digest::SHA1)
  end

  test "cookies from Rails 7.0 and 7.1 before the 7.1 defaults still log the user in" do
    assert_old_cookies_log_in(OpenSSL::Digest::SHA256)
  end
end
