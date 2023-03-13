# pwpush-ephemeral
FROM ruby:3.2-alpine AS build-env

LABEL maintainer='pglombardo@hey.com'

# Required packages
RUN apk upgrade --no-cache \ 
    && apk add --no-cache build-base git curl tzdata zlib-dev nodejs yarn libc6-compat sqlite-dev 

ENV APP_ROOT=/opt/PasswordPusher PATH=${APP_ROOT}:${PATH} HOME=${APP_ROOT}

RUN mkdir -p ${APP_ROOT}
COPY ./ ${APP_ROOT}/

WORKDIR ${APP_ROOT}

# Setting DATABASE_URL is necessary for building.
ENV DATABASE_URL=sqlite3:db/db.sqlite3

RUN gem install bundler

ENV RACK_ENV=private RAILS_ENV=private

RUN bundle config set without 'development production test' \
    && bundle config set with 'sqlite' \
    && bundle config set deployment 'true' \
    && bundle install \
    && yarn install

RUN bundle exec rails assets:precompile && bundle exec rake db:setup

# Removing unneccesary files/directories
RUN rm -rf node_modules tmp/cache vendor/assets spec \
    && rm -rf vendor/bundle/ruby/*/cache/*.gem \
    && find vendor/bundle/ruby/*/gems/ -name "*.c" -delete \
    && find vendor/bundle/ruby/*/gems/ -name "*.o" -delete

################## Build done ##################

FROM ruby:3.2-alpine

LABEL maintainer='pglombardo@hey.com'

# install packages
RUN apk upgrade --no-cache \
    && apk add --no-cache tzdata bash nodejs libc6-compat

# Create a user and group to run the application
ARG UID=1000
ARG GID=1000

RUN addgroup -g "${GID}" pwpusher \
  && adduser -D -u "${UID}" -G pwpusher pwpusher



ENV LC_CTYPE=UTF-8 LC_ALL=en_US.UTF-8
ENV APP_ROOT=/opt/PasswordPusher PATH=${APP_ROOT}:${PATH} HOME=${APP_ROOT}
WORKDIR ${APP_ROOT}
ENV RACK_ENV=private RAILS_ENV=private

RUN mkdir -p ${APP_ROOT} && chown -R pwpusher:pwpusher ${APP_ROOT}
COPY --from=build-env --chown=pwpusher:pwpusher ${APP_ROOT} ${APP_ROOT}

ENV DATABASE_URL=sqlite3:db/db.sqlite3
RUN bundle config set without 'development production test' \
    && bundle config set with 'sqlite' \
    && bundle config set deployment 'true'

USER pwpusher
EXPOSE 5100
ENTRYPOINT ["containers/docker/pwpush-ephemeral/entrypoint.sh"]