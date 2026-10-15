# Development/test image. Ruby and Bundler match Gemfile / Gemfile.lock.
FROM ruby:3.3.12-slim-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential pkg-config git default-libmysqlclient-dev nodejs imagemagick shared-mime-info \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV BUNDLE_WITHOUT=production \
    BUNDLE_JOBS=4

RUN gem install bundler -v 2.5.22
COPY Gemfile Gemfile.lock ./
RUN bundle _2.5.22_ install

COPY . .

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
