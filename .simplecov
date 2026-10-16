# Coverage settings. SimpleCov loads this file when test/test_helper.rb requires it,
# and bin/check-coverage reads the same minimum to gate CI.
SimpleCov.start "rails" do
  # The test run fails if line coverage drops below this. Raise it as coverage grows.
  minimum_coverage 96
end
