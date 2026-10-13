# Development/test image. Ruby and Bundler match Gemfile / Gemfile.lock.
FROM ruby:2.7.2-slim-buster

# Buster is end-of-life; its packages now live on archive.debian.org.
RUN sed -i -e 's|deb.debian.org|archive.debian.org|g' \
           -e 's|security.debian.org|archive.debian.org|g' \
           -e '/buster-updates/d' /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential git default-libmysqlclient-dev nodejs imagemagick shared-mime-info \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV BUNDLE_WITHOUT=production \
    BUNDLE_JOBS=4

RUN gem install bundler -v 2.1.4
COPY Gemfile Gemfile.lock ./
RUN bundle _2.1.4_ install

COPY . .

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
