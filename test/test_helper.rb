require "simplecov"
SimpleCov.start # settings, including the coverage minimum, are in .simplecov

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Every fixture user signs in with this password. It is made up afresh for each run,
  # so no password is written down anywhere in the repository.
  FIXTURE_PASSWORD = SecureRandom.alphanumeric(20).freeze

  FIXTURE_USER_NAMES = YAML.safe_load(ERB.new(Rails.root.join("test/fixtures/users.yml").read).result).keys

  # Fixture users reference avatar.png. Put the file where CarrierWave expects it so
  # their profile pictures are present and they pass validation. This runs before
  # every test because destroying a user also deletes its file.
  setup do
    FIXTURE_USER_NAMES.each do |name|
      dir = Rails.root.join("tmp/test_uploads/uploads/user/profile_picture", ActiveRecord::FixtureSet.identify(name).to_s)
      FileUtils.mkdir_p(dir)
      FileUtils.cp(Rails.root.join("test/fixtures/files/avatar.png"), dir.join("avatar.png"))
    end
  end

  # Add more helper methods to be used by all tests here...
end

class ActionDispatch::IntegrationTest
  def log_in_as(user, password: FIXTURE_PASSWORD, remember_me: "0")
    post login_path, params: { session: { email: user.email, password: password, remember_me: remember_me } }
  end
end
