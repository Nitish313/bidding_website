require 'carrierwave/orm/activerecord'

# Keep files uploaded by the test suite out of public/.
if Rails.env.test?
  CarrierWave.configure do |config|
    config.root = Rails.root.join("tmp/test_uploads")
    config.enable_processing = false
  end
end
