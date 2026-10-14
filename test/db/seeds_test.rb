require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  CATEGORIES = ["Web Development", "Web Design", "Content Writer", "Project Management", "SEO service", "Marketing/Sales"].freeze
  SEED_VARS = %w[SEED_ADMIN_EMAIL SEED_ADMIN_PASSWORD].freeze

  def setup
    @saved_env = ENV.to_h.slice(*SEED_VARS)
    SEED_VARS.each { |var| ENV.delete(var) }
  end

  def teardown
    SEED_VARS.each { |var| ENV.delete(var) }
    @saved_env.each { |var, value| ENV[var] = value }
  end

  def run_seeds
    out, = capture_io { load Rails.root.join("db/seeds.rb") }
    out
  end

  test "creates an activated admin with the password from SEED_ADMIN_PASSWORD" do
    ENV["SEED_ADMIN_EMAIL"] = "boss@example.com"
    ENV["SEED_ADMIN_PASSWORD"] = "chosen-secret-123"
    output = run_seeds
    admin = User.find_by!(email: "boss@example.com")
    assert_predicate admin, :admin?
    assert_predicate admin, :activated?
    assert admin.authenticate("chosen-secret-123")
    assert_no_match "chosen-secret-123", output
  end

  test "generates and prints a random password when none is given" do
    ENV["SEED_ADMIN_EMAIL"] = "boss@example.com"
    output = run_seeds
    password = output[/with password (\S+)/, 1]
    assert_not_nil password, "expected the generated password in: #{output.inspect}"
    assert_operator password.length, :>=, 16
    assert User.find_by!(email: "boss@example.com").authenticate(password)
  end

  test "never uses the old hardcoded password" do
    users(:admin).destroy
    run_seeds
    admin = User.find_by!(email: "admin@example.com")
    assert_not admin.authenticate("password")
  end

  test "creates each job category once" do
    run_seeds
    CATEGORIES.each { |name| assert_equal 1, Category.where(name: name).count, name }
  end

  test "can be run again without errors, duplicates or a password change" do
    ENV["SEED_ADMIN_EMAIL"] = "boss@example.com"
    ENV["SEED_ADMIN_PASSWORD"] = "first-secret-123"
    run_seeds
    ENV["SEED_ADMIN_PASSWORD"] = "second-secret-456"
    assert_no_difference ["User.count", "Category.count"] do
      run_seeds
    end
    assert User.find_by!(email: "boss@example.com").authenticate("first-secret-123")
  end
end
