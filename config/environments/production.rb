Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Serve precompiled assets from /public: hosts such as Render put no separate web
  # server in front of the app.
  config.public_file_server.enabled = true

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :terser
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # The host (Render) ends HTTPS and redirects plain HTTP itself, then forwards requests
  # to the app over HTTP. Treat every request as HTTPS, send Strict-Transport-Security,
  # and mark cookies secure.
  config.assume_ssl = true
  config.force_ssl = true

  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prepend all log lines with the following tags.

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "bidding-website_#{Rails.env}"

  config.action_mailer.perform_caching = false

  # Links in emails point at APP_HOST, or on Render at the service's own address.
  config.action_mailer.default_url_options = {
    host: ENV["APP_HOST"].presence || ENV.fetch("RENDER_EXTERNAL_HOSTNAME", "localhost"),
    protocol: "https"
  }

  # Account activation and password reset emails go out through any SMTP provider
  # (Brevo, Mailgun, Gmail, ...). Delivery failures are raised so they get reported.
  if ENV["SMTP_ADDRESS"].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV["SMTP_ADDRESS"],
      port: ENV.fetch("SMTP_PORT", 587).to_i,
      user_name: ENV.fetch("SMTP_USERNAME"),
      password: ENV.fetch("SMTP_PASSWORD"),
      authentication: :plain,
      enable_starttls_auto: true
    }
    config.action_mailer.raise_delivery_errors = true
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  # Request logs are JSON lines (config/initializers/lograge.rb) that carry their own
  # request id, so print each log line as-is, without Rails' prefix.
  config.log_formatter = proc { |_severity, _time, _progname, message| "#{message}\n" }

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
end
