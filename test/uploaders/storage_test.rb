require "test_helper"
require "open3"

# Where uploads are stored is decided when the app boots, so each case boots it in a
# fresh process with its own environment.
class StorageTest < ActiveSupport::TestCase
  OBJECT_STORAGE = {
    "STORAGE_BUCKET" => "bidding-uploads",
    "STORAGE_ENDPOINT" => "https://account-id.r2.cloudflarestorage.com",
    "STORAGE_ACCESS_KEY_ID" => "test-key-id",
    "STORAGE_SECRET_ACCESS_KEY" => "test-secret"
  }.freeze

  # Prints the storage in use and the link the app would give for a stored solution file.
  SCRIPT = <<~RUBY.freeze
    uploader = AttachmentUploader.new(Solution.new(id: 7), :attachment_1)
    uploader.retrieve_from_store!("final.pdf")
    puts uploader.class.storage, uploader.url
  RUBY

  def boot_with(env)
    output, status = Open3.capture2e({ "RAILS_ENV" => "test" }.merge(env),
                                     "bin/rails", "runner", SCRIPT, chdir: Rails.root.to_s)
    assert_predicate status, :success?, output
    output.lines.last(2).map(&:strip)
  end

  test "without a bucket, uploads are stored as local files" do
    storage, url = boot_with({})
    assert_equal "CarrierWave::Storage::File", storage
    assert_equal "/uploads/solution/attachment_1/7/final.pdf", url
  end

  test "with a bucket, uploads go to S3-compatible storage behind signed links that expire" do
    storage, url = boot_with(OBJECT_STORAGE)
    assert_equal "CarrierWave::Storage::Fog", storage
    uri = URI(url)
    assert_equal "account-id.r2.cloudflarestorage.com", uri.host
    assert_equal "/bidding-uploads/uploads/solution/attachment_1/7/final.pdf", uri.path
    query = URI.decode_www_form(uri.query).to_h
    assert_equal "600", query["X-Amz-Expires"], "links expire after ten minutes"
    assert_predicate query["X-Amz-Signature"], :present?, "files are private, so links are signed"
  end

  test "a bucket without credentials stops the app from booting" do
    output, status = Open3.capture2e({ "RAILS_ENV" => "test", "STORAGE_BUCKET" => "bidding-uploads" },
                                     "bin/rails", "runner", "puts :booted", chdir: Rails.root.to_s)
    assert_not status.success?
    assert_match "STORAGE_ACCESS_KEY_ID", output
  end
end
