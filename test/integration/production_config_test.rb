require "test_helper"
require "open3"
require "json"

# Production settings that come from the environment (see the Deploying section of the
# README). Each case boots the app in production mode in a fresh process.
class ProductionConfigTest < ActiveSupport::TestCase
  SCRIPT = <<~RUBY.freeze
    config = Rails.application.config
    puts JSON.generate(
      delivery_method: ActionMailer::Base.delivery_method,
      smtp: ActionMailer::Base.smtp_settings,
      url_options: ActionMailer::Base.default_url_options,
      from: ApplicationMailer.default[:from],
      force_ssl: config.force_ssl,
      assume_ssl: config.assume_ssl,
      log_level: Rails.logger.level,
      static_files: config.public_file_server.enabled
    )
  RUBY

  def production_config(env = {})
    env = { "RAILS_ENV" => "production", "SECRET_KEY_BASE_DUMMY" => "1", "SENTRY_DSN" => nil }.merge(env)
    output, status = Open3.capture2e(env, "bin/rails", "runner", SCRIPT, chdir: Rails.root.to_s)
    assert_predicate status, :success?, output
    JSON.parse(output.lines.last, symbolize_names: true)
  end

  test "emails go out over SMTP with links to the app's own address" do
    config = production_config(
      "SMTP_ADDRESS" => "smtp-relay.example.com", "SMTP_PORT" => "2525",
      "SMTP_USERNAME" => "mailer", "SMTP_PASSWORD" => "secret",
      "MAIL_FROM" => "Bidding Website <hello@example.org>", "APP_HOST" => "bids.example.org"
    )
    assert_equal "smtp", config[:delivery_method]
    assert_equal({ address: "smtp-relay.example.com", port: 2525, user_name: "mailer", password: "secret",
                   authentication: "plain", enable_starttls_auto: true },
                 config[:smtp].slice(:address, :port, :user_name, :password, :authentication, :enable_starttls_auto))
    assert_equal({ host: "bids.example.org", protocol: "https" }, config[:url_options])
    assert_equal "Bidding Website <hello@example.org>", config[:from]
  end

  test "on Render, links use the service's own address unless APP_HOST is set" do
    config = production_config("RENDER_EXTERNAL_HOSTNAME" => "bidding-website.onrender.com")
    assert_equal "bidding-website.onrender.com", config[:url_options][:host]
  end

  test "behind the host's HTTPS proxy, cookies are secure and browsers are told to stay on HTTPS" do
    config = production_config
    assert config[:assume_ssl], "the host's proxy ends HTTPS before the request reaches the app"
    assert config[:force_ssl]
  end

  test "logs at info level and serves its own assets by default" do
    config = production_config
    assert_equal Logger::INFO, config[:log_level]
    assert config[:static_files]
  end
end
