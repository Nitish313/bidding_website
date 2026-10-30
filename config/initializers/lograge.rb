# Logs each request as one JSON line (method, path, status, duration, request id and,
# when logged in, the user id) instead of Rails' multi-line request logs.
#
# On everywhere except development, where the detailed multi-line logs are more useful
# while debugging. Health checks are left out to keep the logs readable.
Rails.application.configure do
  config.lograge.enabled = !Rails.env.development?
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.ignore_actions = ["HealthController#show"]
  config.lograge.custom_payload do |controller|
    { request_id: controller.request.request_id, user_id: controller.session[:user_id] }.compact
  end
end
