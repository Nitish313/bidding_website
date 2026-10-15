require "test_helper"

# Validation of user-supplied fields: amounts, text lengths and allowed values.
class InputValidationTest < ActiveSupport::TestCase
  LONG = "x" * 256

  def gig(attrs = {})
    Gig.new({ name: "Logo", description: "A logo.", budget: 100, location: "Remote", skill_list: "design",
              category: categories(:web_development), user: users(:client) }.merge(attrs))
  end

  def proposal(attrs = {})
    Proposal.new({ name: "Bid", bid: 100, description: "Offer", gig: gigs(:blog_posts), user: users(:freelancer) }.merge(attrs))
  end

  def assert_invalid(record, attribute)
    assert_not record.save, "expected #{record.class} to be invalid on #{attribute}"
    assert_predicate record.errors[attribute], :any?, "no error on #{attribute}: #{record.errors.full_messages.inspect}"
  end

  # gigs

  test "a gig with a normal budget is valid" do
    assert_predicate gig, :valid?
  end

  test "a gig budget must be a positive whole number" do
    [0, -50, 12.5, "abc"].each { |budget| assert_invalid gig(budget: budget), :budget }
  end

  test "a gig budget too large for the database is refused instead of crashing" do
    assert_invalid gig(budget: 3_000_000_000), :budget
  end

  test "gig names and locations are limited to 255 characters" do
    assert_invalid gig(name: LONG), :name
    assert_invalid gig(location: LONG), :location
  end

  test "a skill longer than 255 characters makes the gig invalid instead of crashing" do
    assert_not gig(skill_list: "ruby, #{LONG}").save
  end

  # proposals

  test "a proposal bid must be a positive whole number" do
    [0, -1, 99.99].each { |bid| assert_invalid proposal(bid: bid), :bid }
  end

  test "a proposal bid too large for the database is refused" do
    assert_invalid proposal(bid: 3_000_000_000), :bid
  end

  test "proposal names are limited to 255 characters" do
    assert_invalid proposal(name: LONG), :name
  end

  # users

  test "a user's role must be Client or Freelancer" do
    user = users(:client)
    %w[Client Freelancer].each do |role|
      user.role = role
      user.education = "BSc"
      user.experience = 1
      assert_predicate user, :valid?, role
    end
    ["Admin", "Hacker", ""].each do |role|
      user.role = role
      assert_invalid user, :role
    end
  end

  test "admins do not need a role" do
    assert_predicate users(:admin), :valid?
    assert_nil users(:admin).role
  end

  test "experience must be a whole number of years from 0 to 80" do
    user = users(:freelancer)
    [-1, 81, 2.5].each do |years|
      user.experience = years
      assert_invalid user, :experience
    end
    user.experience = 0
    assert_predicate user, :valid?
  end

  test "education and industry are limited to 255 characters" do
    user = users(:freelancer)
    user.education = LONG
    assert_invalid user, :education
    user.education = "BSc"
    user.industry = LONG
    assert_invalid user, :industry
  end

  # solutions

  test "solution names are limited to 255 characters" do
    solution = solutions(:landing_page_delivery)
    solution.name = LONG
    assert_invalid solution, :name
  end
end
