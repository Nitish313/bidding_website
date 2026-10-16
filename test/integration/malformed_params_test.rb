require "test_helper"

# Forms submitted with a missing or wrongly shaped field set (for example a plain
# string where a set of fields is expected) are rejected as a bad request (400)
# instead of crashing the app with a 500.
class MalformedParamsTest < ActionDispatch::IntegrationTest
  def assert_bad_request(&)
    assert_raises(ActionController::ParameterMissing, &)
  end

  test "login without credentials or with a malformed session field" do
    assert_bad_request { post login_path }
    assert_bad_request { post login_path, params: { session: "admin" } }
  end

  test "password reset request without an email or with a malformed field" do
    assert_bad_request { post password_resets_path }
    assert_bad_request { post password_resets_path, params: { password_reset: "someone" } }
  end

  test "choosing a new password with a malformed user field" do
    user = users(:freelancer)
    user.create_reset_digest
    assert_bad_request do
      patch password_reset_path(user.reset_token), params: { email: user.email, user: "secret" }
    end
  end

  test "signup and profile update with a malformed user field" do
    assert_bad_request { post users_path, params: { user: "nina" } }
    log_in_as(users(:client))
    assert_bad_request { patch user_path(users(:client)), params: { user: "Carl" } }
  end

  test "posting and editing a gig with a malformed gig field" do
    log_in_as(users(:client))
    assert_bad_request { post gigs_path, params: { gig: "spam" } }
    assert_bad_request { patch gig_path(gigs(:landing_page)), params: { gig: "spam" } }
  end

  test "bidding with a malformed proposal field" do
    log_in_as(users(:freelancer))
    assert_bad_request { post gig_proposals_path(gigs(:blog_posts)), params: { proposal: "500" } }
  end

  test "submitting a solution with a malformed solution field" do
    proposal = proposals(:landing_page_bid)
    proposal.gig.update_columns(awarded_proposal: proposal.id)
    log_in_as(users(:freelancer))
    assert_bad_request { post proposal_solutions_path(proposal), params: { solution: "done" } }
  end

  test "a bad request is answered with HTTP 400" do
    assert_equal 400, ActionDispatch::ExceptionWrapper.status_code_for_exception("ActionController::ParameterMissing")
  end
end
