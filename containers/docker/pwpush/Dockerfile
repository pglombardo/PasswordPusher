# Setting global arguments
ARG BUNDLE_WITH=sqlite:mysql:postgres
ARG BUNDLE_WITHOUT=development:test:private
ARG BUNDLE_DEPLOYMENT=true

# pwpush-ephemeral
FROM ruby:3.2-alpine AS build-env

# include global args
ARG BUNDLE_WITH
ARG BUNDLE_WITHOUT
ARG BUNDLE_DEPLOYMENT

LABEL org.opencontainers.image.authors ='pglombardo@hey.com'

# Required packages
RUN apk add --no-cache build-base git curl tzdata zlib-dev nodejs yarn libc6-compat sqlite-dev mariadb-dev libpq-dev

ENV APP_ROOT=/opt/PasswordPusher

WORKDIR ${APP_ROOT}
COPY ./ ${APP_ROOT}/

ENV RACK_ENV=production RAILS_ENV=production

RUN bundle config set without "${BUNDLE_WITHOUT}" \
    && bundle config set deployment "${BUNDLE_DEPLOYMENT}" \
    && bundle config set with "${BUNDLE_WITH}" \
    && bundle install

RUN yarn install

# Set DATABASE_URL to sqlite to have a ready
# to use db file for ephemeral configuration
ENV DATABASE_URL=sqlite3:db/db.sqlite3
RUN bundle exec rails assets:precompile && bundle exec rake db:setup

# Removing unneccesary files/directories
RUN rm -rf node_modules tmp/cache vendor/assets spec \
    && rm -rf vendor/bundle/ruby/*/cache/*.gem \
    && find vendor/bundle/ruby/*/gems/ -name "*.c" -delete \
    && find vendor/bundle/ruby/*/gems/ -name "*.o" -delete

################## Build done ##################

FROM ruby:3.2-alpine

# include global args
ARG BUNDLE_WITH
ARG BUNDLE_WITHOUT
ARG BUNDLE_DEPLOYMENT

LABEL maintainer='pglombardo@hey.com'

# install packages
RUN apk add --no-cache tzdata bash nodejs libc6-compat sqlite-dev mariadb-connector-c libpq

# Create a user and group to run the application
ARG UID=1000
ARG GID=1000

RUN addgroup -g "${GID}" pwpusher \
  && adduser -D -u "${UID}" -G pwpusher pwpusher

ENV LC_CTYPE=UTF-8 LC_ALL=en_US.UTF-8
ENV APP_ROOT=/opt/PasswordPusher
WORKDIR ${APP_ROOT}
ENV RACK_ENV=production RAILS_ENV=production

COPY --from=build-env --chown=pwpusher:pwpusher ${APP_ROOT} ${APP_ROOT}

RUN bundle config set without "${BUNDLE_WITHOUT}" \
    && bundle config set with "${BUNDLE_WITH}" \
    && bundle config set deployment "${BUNDLE_DEPLOYMENT}"

USER pwpusher
EXPOSE 5100
ENTRYPOINT ["containers/docker/pwpush/entrypoint.sh"]