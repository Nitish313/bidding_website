require "test_helper"

class AttachmentUploaderTest < ActiveSupport::TestCase
  def setup
    @uploader = AttachmentUploader.new(gigs(:landing_page), :attachments)
  end

  def upload(name, type)
    Rack::Test::UploadedFile.new(file_fixture(name), type)
  end

  test "accepts common document and image files" do
    @uploader.cache!(upload("brief.pdf", "application/pdf"))
    assert_predicate @uploader, :cached?
    AttachmentUploader.new(gigs(:landing_page), :attachments).cache!(upload("solution.txt", "text/plain"))
    AttachmentUploader.new(gigs(:landing_page), :attachments).cache!(upload("wide.png", "image/png"))
  end

  test "rejects HTML, which would run as a page on this site" do
    error = assert_raises(CarrierWave::IntegrityError) { @uploader.cache!(upload("page.html", "text/html")) }
    assert_match "not allowed", error.message
  end

  test "rejects SVG, which can carry scripts" do
    assert_raises(CarrierWave::IntegrityError) { @uploader.cache!(upload("drawing.svg", "image/svg+xml")) }
  end

  test "rejects files larger than 20 MB" do
    Tempfile.create(["huge", ".zip"]) do |file|
      file.truncate(20.megabytes + 1)
      error = assert_raises(CarrierWave::IntegrityError) do
        @uploader.cache!(Rack::Test::UploadedFile.new(file.path, "application/zip"))
      end
      assert_match(/size/i, error.message)
    end
  end

  test "stores attachments per record" do
    assert_equal "uploads/gig/attachments/#{gigs(:landing_page).id}", @uploader.store_dir
  end
end
