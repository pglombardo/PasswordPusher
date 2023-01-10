# pwpush-ephemeral
FROM ruby:3.1-slim

LABEL maintainer='pglombardo@hey.com'

ENV APP_ROOT=/opt/PasswordPusher
ENV PATH=${APP_ROOT}:${PATH} HOME=${APP_ROOT}

RUN apt-get update && apt-get install -y curl ca-certificates gnupg

# Required packages
RUN apt-get update && apt-get install -qq -y --assume-yes build-essential apt-utils libpq-dev git curl tzdata libsqlite3-0 libsqlite3-dev zlib1g-dev

RUN mkdir -p ${APP_ROOT}
ADD ./ ${APP_ROOT}/

EXPOSE 5100

RUN gem install bundler

WORKDIR ${APP_ROOT}

ENV RACK_ENV=private
ENV RAILS_ENV=private

RUN bundle config set without 'development production test'
RUN bundle config set deployment 'true'

RUN bundle install
RUN bundle exec rails assets:precompile
RUN bundle exec rake db:setup

ENTRYPOINT ["containers/docker/pwpush-ephemeral/entrypoint.sh"]
