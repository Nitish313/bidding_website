require "test_helper"
require "open3"
require "json"

class CheckCoverageTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join("bin/check-coverage").to_s

  def run_check(line_coverage)
    Dir.mktmpdir do |dir|
      result = File.join(dir, ".last_run.json")
      File.write(result, JSON.generate(result: { line: line_coverage })) unless line_coverage.nil?
      Open3.capture2e(SCRIPT, result)
    end
  end

  test "the minimum is read from .simplecov" do
    output, status = run_check(100.0)
    assert_predicate status, :success?
    assert_match "minimum 96%", output
  end

  test "passes and reports the coverage when it meets the minimum" do
    output, status = run_check(96.0)
    assert_predicate status, :success?
    assert_match "Line coverage 96.0%", output
  end

  test "fails when coverage is below the minimum" do
    output, status = run_check(95.9)
    assert_not status.success?
    assert_match "below the minimum", output
  end

  test "fails when there is no coverage result to check" do
    output, status = run_check(nil)
    assert_not status.success?
    assert_match "No coverage result", output
  end
end
