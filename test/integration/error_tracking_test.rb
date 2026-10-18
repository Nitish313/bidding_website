require "test_helper"
require "minitest/mock"
require "sentry/test_helper"

# Unexpected errors are reported to Sentry; routine 404s and 400s are not. The test
# helper captures events in memory instead of sending them anywhere.
class ErrorTrackingTest < ActionDispatch::IntegrationTest
  include Sentry::TestHelper

  setup { setup_sentry_test }
  teardown { teardown_sentry_test }

  def raise_on_gig_page(error)
    Gig.stub(:find, ->(*) { raise error }) do
      assert_raises(error.class) { get gig_path(gigs(:landing_page)) }
    end
  end

  test "an unexpected error is reported" do
    raise_on_gig_page(RuntimeError.new("database on fire"))
    assert_equal 1, sentry_events.size
    reported = sentry_events.last.exception.values.last
    assert_equal "RuntimeError", reported.type
    assert_match "database on fire", reported.value
  end

  test "the report names the logged-in user by id only" do
    log_in_as(users(:client))
    raise_on_gig_page(RuntimeError.new("boom"))
    user = sentry_events.last.user
    assert_equal users(:client).id, user[:id]
    assert_nil user[:email]
  end

  test "a missing record (404) is not reported" do
    assert_raises(ActiveRecord::RecordNotFound) { get gig_path(id: 0) }
    assert_empty sentry_events
  end

  test "a malformed form (400) is not reported" do
    assert_raises(ActionController::ParameterMissing) { post login_path, params: { session: "x" } }
    assert_empty sentry_events
  end

  test "no personal data is sent by default" do
    assert_not Sentry.configuration.send_default_pii
  end
end
