# Liveness and readiness check for load balancers and monitoring.
# Skips the unread-count filters so it never loads a user or touches the session.
class HealthController < ApplicationController
  skip_before_action :unread_counts, :unread_notification_counts

  def show
    response.headers["Cache-Control"] = "no-store"
    ActiveRecord::Base.connection.select_value("SELECT 1")
    render json: { status: "ok", database: "ok" }
  rescue ActiveRecord::ActiveRecordError, Mysql2::Error
    render json: { status: "error", database: "unavailable" }, status: :service_unavailable
  end
end
