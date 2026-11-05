require "carrierwave/orm/activerecord"

# Keep files uploaded by the test suite out of public/.
if Rails.env.test?
  CarrierWave.configure do |config|
    config.root = Rails.root.join("tmp/test_uploads")
    config.enable_processing = false
  end
end

# With STORAGE_BUCKET set, uploads go to S3-compatible object storage (Cloudflare R2,
# AWS S3, Backblaze B2, ...) instead of public/uploads, which a host such as Render
# wipes on every deploy. Files stay private: links to them are signed and expire.
if ENV["STORAGE_BUCKET"].present?
  CarrierWave.configure do |config|
    config.storage = :fog
    config.fog_credentials = {
      provider: "AWS",
      aws_access_key_id: ENV.fetch("STORAGE_ACCESS_KEY_ID"),
      aws_secret_access_key: ENV.fetch("STORAGE_SECRET_ACCESS_KEY"),
      # R2 uses the region "auto"; AWS needs the bucket's own region.
      region: ENV.fetch("STORAGE_REGION", "auto"),
      # Leave STORAGE_ENDPOINT unset for AWS S3.
      endpoint: ENV["STORAGE_ENDPOINT"].presence,
      path_style: true
    }.compact
    config.fog_directory = ENV["STORAGE_BUCKET"]
    config.fog_public = false
    config.fog_authenticated_url_expiration = 10.minutes.to_i
  end
end
