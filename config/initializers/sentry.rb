# Reports unexpected errors to Sentry (or any Sentry-compatible service). Nothing is sent
# unless SENTRY_DSN is set. Routine errors such as missing records (404) and malformed
# requests (400) are ignored by sentry-rails' default exclusions.
Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"].presence
  config.environment = Rails.env
  config.release = ENV["SENTRY_RELEASE"].presence
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  # Never send cookies, form contents, IP addresses or other personal data.
  config.send_default_pii = false
  # Performance tracing is off unless a sample rate between 0 and 1 is configured.
  config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", 0).to_f
end
