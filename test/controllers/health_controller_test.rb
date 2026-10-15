require "test_helper"
require "minitest/mock"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "reports ok when the app and database are up" do
    get health_path
    assert_response :ok
    assert_equal "application/json", response.media_type
    assert_equal({ "status" => "ok", "database" => "ok" }, response.parsed_body)
  end

  test "reports 503 when the database is unreachable" do
    failing_query = ->(*) { raise ActiveRecord::ConnectionNotEstablished, "connection refused" }
    ActiveRecord::Base.connection.stub(:select_value, failing_query) do
      get health_path
    end
    assert_response :service_unavailable
    assert_equal({ "status" => "error", "database" => "unavailable" }, response.parsed_body)
  end

  test "needs no login and sets no session cookie" do
    get health_path
    assert_response :ok
    assert_nil response.headers["Set-Cookie"]
  end

  test "is not cached" do
    get health_path
    assert_match "no-store", response.headers["Cache-Control"]
  end
end
