require "test_helper"

# Every request outside development is logged as a single JSON line (lograge).
class RequestLoggingTest < ActionDispatch::IntegrationTest
  def setup
    @log = StringIO.new
    @original_logger = Lograge.logger
    Lograge.logger = ActiveSupport::Logger.new(@log)
  end

  def teardown
    Lograge.logger = @original_logger
  end

  def logged_requests
    @log.string.lines.filter_map do |line|
      JSON.parse(line[line.index("{")..])
    rescue JSON::ParserError, TypeError
      nil
    end
  end

  test "request logging is on outside development" do
    assert Rails.application.config.lograge.enabled
  end

  test "a request is logged as one JSON line with method, path, status and request id" do
    get gigs_path
    entry = logged_requests.find { |line| line["path"] == "/gigs" }
    assert entry, "no JSON log line for /gigs in: #{@log.string.inspect}"
    assert_equal "GET", entry["method"]
    assert_equal 200, entry["status"]
    assert_equal "GigsController", entry["controller"]
    assert_predicate entry["request_id"], :present?
  end

  test "the logged-in user's id is included" do
    log_in_as(users(:client))
    get gigs_path
    entry = logged_requests.find { |line| line["path"] == "/gigs" }
    assert_equal users(:client).id, entry["user_id"]
  end

  test "health checks are not logged" do
    get health_path
    assert_empty(logged_requests.select { |line| line["path"] == "/health" })
  end
end
