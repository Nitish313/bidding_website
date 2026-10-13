require "test_helper"

class FixtureSanityTest < ActiveSupport::TestCase
  test "fixture users are valid" do
    User.find_each { |user| assert_predicate user, :valid?, "#{user.email}: #{user.errors.full_messages.to_sentence}" }
  end
end
