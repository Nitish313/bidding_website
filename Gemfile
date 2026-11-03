source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.12'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 8.1.3'
# Rails 8 no longer depends on Sprockets; the asset pipeline here still uses it.
gem 'sprockets-rails', '~> 3.5'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.4.4', '< 0.6.0'
# Use Puma as the app server
gem 'puma', '~> 7.2'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Terser to minify JavaScript assets in production
gem 'terser', '~> 1.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 5.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false
gem 'bootstrap-sass'
gem 'jquery-rails', '~> 4.6'
gem 'will_paginate'
gem 'bootstrap-will_paginate'
gem 'mini_magick'
gem 'carrierwave', '~> 3.1'
gem 'lograge', '~> 0.14.0'
# Error reporting; does nothing until SENTRY_DSN is set.
gem 'sentry-ruby', '~> 7.1'
gem 'sentry-rails', '~> 7.1'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rubocop', '~> 1.92.0', require: false
  gem 'rubocop-rails', '~> 2.38.0', require: false
  gem 'rubocop-minitest', '~> 0.41.0', require: false
  gem 'bundler-audit', '~> 0.9', require: false
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  gem 'listen', '~> 3.5'
  gem 'letter_opener_web', '~> 3.0'
end

group :production do 
  gem 'pg'
end

group :test do
  # Minitest 6 drops minitest/mock and is not supported by Rails 7.1's test runner.
  gem 'minitest', '~> 6.0'
  gem 'simplecov', '~> 1.3.2', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
#gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
