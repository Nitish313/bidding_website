require "test_helper"

class ImageUploaderTest < ActiveSupport::TestCase
  def setup
    @uploader = ImageUploader.new(users(:client), :profile_picture)
  end

  def teardown
    ImageUploader.enable_processing = false
  end

  def upload(name, type = "image/png")
    Rack::Test::UploadedFile.new(file_fixture(name), type)
  end

  test "accepts png, jpg, jpeg and gif files" do
    assert_equal %w[jpg jpeg gif png], @uploader.extension_allowlist
    @uploader.cache!(upload("wide.png"))
    assert_predicate @uploader, :cached?
  end

  test "rejects files that are not images by name" do
    error = assert_raises(CarrierWave::IntegrityError) { @uploader.cache!(upload("solution.txt", "text/plain")) }
    assert_match "not allowed", error.message
  end

  test "rejects a non-image file renamed to look like an image" do
    assert_raises(CarrierWave::IntegrityError) { @uploader.cache!(upload("not_an_image.png")) }
  end

  test "rejects SVG, which can carry scripts" do
    assert_raises(CarrierWave::IntegrityError) { @uploader.cache!(upload("drawing.svg", "image/svg+xml")) }
  end

  test "stores pictures per user" do
    assert_equal "uploads/user/profile_picture/#{users(:client).id}", @uploader.store_dir
  end

  test "makes a thumbnail that fits in 50x50 and keeps the aspect ratio" do
    ImageUploader.enable_processing = true
    @uploader.cache!(upload("wide.png"))
    thumb = MiniMagick::Image.open(@uploader.thumb.path)
    assert_equal [50, 25], [thumb.width, thumb.height]
  end
end
