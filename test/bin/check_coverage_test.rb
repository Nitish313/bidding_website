require "test_helper"
require "open3"
require "json"

class CheckCoverageTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join("bin/check-coverage").to_s

  def run_check(line_coverage, env: {})
    Dir.mktmpdir do |dir|
      result = File.join(dir, ".last_run.json")
      File.write(result, JSON.generate(result: { line: line_coverage })) unless line_coverage.nil?
      Open3.capture2e(env, SCRIPT, result)
    end
  end

  # GitHub Actions sets GITHUB_STEP_SUMMARY to a file whose Markdown shows on the job page.
  def job_summary_for(line_coverage)
    Dir.mktmpdir do |dir|
      summary = File.join(dir, "summary.md")
      File.write(summary, "Earlier step's summary\n")
      _, status = run_check(line_coverage, env: { "GITHUB_STEP_SUMMARY" => summary })
      [File.read(summary), status]
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

  test "adds the coverage and minimum to the CI job summary" do
    summary, status = job_summary_for(97.25)
    assert_predicate status, :success?
    assert summary.start_with?("Earlier step's summary\n"), "appends instead of overwriting"
    assert_match "| Line coverage | 97.25% |", summary
    assert_match "| Minimum | 96% |", summary
    assert_match "| Result | ok |", summary
  end

  test "the job summary also shows a coverage drop" do
    summary, status = job_summary_for(90.0)
    assert_not status.success?
    assert_match "| Line coverage | 90.0% |", summary
    assert_match "| Result | below the minimum |", summary
  end

  test "writes no job summary outside CI" do
    output, status = run_check(97.0)
    assert_predicate status, :success?
    assert_no_match "|", output
  end
end
