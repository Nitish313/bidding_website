# Rails 7.0 derives cookie keys with SHA256 instead of SHA1. Without this, every
# session and remember-me cookie issued before the upgrade would stop working and
# all users would be logged out. Old cookies are accepted and rewritten with the
# new keys on the next response. Safe to delete once old cookies have expired.
Rails.application.config.after_initialize do
  Rails.application.config.action_dispatch.cookies_rotations.tap do |cookies|
    config = Rails.application.config.action_dispatch
    key_generator = ActiveSupport::KeyGenerator.new(
      Rails.application.secret_key_base, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1
    )
    key_len = ActiveSupport::MessageEncryptor.key_len

    cookies.rotate :encrypted, key_generator.generate_key(config.authenticated_encrypted_cookie_salt, key_len)
    cookies.rotate :signed, key_generator.generate_key(config.signed_cookie_salt)
  end
end
