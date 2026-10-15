require "test_helper"

class ZeitwerkTest < ActiveSupport::TestCase
  test "the app uses the zeitwerk autoloader" do
    assert_predicate Rails.autoloaders, :zeitwerk_enabled?
  end

  test "every file under app/ eager loads with the constant its name implies" do
    assert_nothing_raised { Rails.application.eager_load! }
  end
end
