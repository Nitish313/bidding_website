# Coverage settings. test/test_helper.rb starts SimpleCov, which loads this file, and
# bin/check-coverage reads the same minimum to gate CI.
SimpleCov.configure do
  load_profile "rails"
  # The test run fails if line coverage drops below this. Raise it as coverage grows.
  minimum_coverage 96
end
