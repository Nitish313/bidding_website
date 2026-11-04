require "test_helper"
require "minitest/mock"
require "sentry/test_helper"
require "open3"

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

# Only production reports errors, so local test and development runs never send events,
# even when SENTRY_DSN is set in .env. Sentry's test helper above swaps in its own
# configuration for the rest of the run, so this boots the app in a fresh process.
class ErrorTrackingEnvironmentsTest < ActiveSupport::TestCase
  def reporting_enabled_in?(environment)
    env = { "RAILS_ENV" => environment, "SENTRY_DSN" => "https://public@sentry.example.invalid/1",
            "SECRET_KEY_BASE_DUMMY" => "1" }
    output, status = Open3.capture2e(env, "bin/rails", "runner",
                                     "puts Sentry.configuration.enabled_in_current_env?", chdir: Rails.root.to_s)
    assert_predicate status, :success?, output
    output.lines.last.strip == "true"
  end

  test "errors are reported from production only, even with a DSN set" do
    assert reporting_enabled_in?("production")
    assert_not reporting_enabled_in?("test")
    assert_not reporting_enabled_in?("development")
  end
end
