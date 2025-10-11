# Setting global arguments
ARG BUNDLE_WITHOUT=development:test
ARG BUNDLE_DEPLOYMENT=true

FROM ruby:3.4.7-alpine AS build-env

# include global args
ARG BUNDLE_WITHOUT
ARG BUNDLE_DEPLOYMENT

LABEL org.opencontainers.image.authors='pglombardo@hey.com'

# Required build packages
RUN apk add --no-cache \
    git \
    build-base \
    musl-dev \
    libc6-compat \
    libpq-dev \
    mariadb-dev \
    nodejs \
    sqlite-dev \
    tzdata \
    yaml-dev \
    yarn \
    pkgconf \
    openssl-dev


ENV APP_ROOT=/opt/PasswordPusher

WORKDIR ${APP_ROOT}
COPY Gemfile Gemfile.lock package.json yarn.lock ./

ENV RACK_ENV=production RAILS_ENV=production

RUN bundle config set without "${BUNDLE_WITHOUT}" \
    && bundle config set deployment "${BUNDLE_DEPLOYMENT}" \
    && bundle install \
    && rm -rf vendor/bundle/ruby/*/cache \
    && rm -rf vendor/bundle/ruby/*/bundler/gems/*/.git \
    && find vendor/bundle/ruby/*/gems/ -name "*.c" -delete \
    && find vendor/bundle/ruby/*/gems/ -name "*.o" -delete

RUN yarn install

COPY ./ ${APP_ROOT}/

RUN yarn build

# Set DATABASE_URL to sqlite to have a ready
# to use db file for ephemeral configuration
ENV DATABASE_URL=sqlite3:db/db.sqlite3

# Set a default secret_key_base
# For those self-hosting this app, you should
# generate your own secret_key_base and set it
# in your environment.
# 1. Generate a secret_key_base value with:
#    bundle exec rails secret
# 2. Set the secret_key_base in your environment:
#    SECRET_KEY_BASE=<value>
ENV SECRET_KEY_BASE=783ff1544b9612d8bceb8e26a0bab0cf22543eec658a498e7ef9e1d617976f960092005c8a54cb588759dc6dd8fd054bc4eca4a94dd7b96c6efda4a14a01bfbd

# Precompile bootsnap cache only for amd64 architecture
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      bundle exec bootsnap precompile --gemfile && \
      bundle exec bootsnap precompile app/ lib/ ; \
    else \
      echo "Skipping bootsnap precompilation for $TARGETARCH" ; \
    fi

RUN bundle exec rails assets:precompile
RUN bundle exec rake db:setup && rm -rf tmp/cache tmp/pids tmp/sockets app/assets/images/features

################## Build done ##################

FROM ruby:3.4.7-alpine

# include global args
ARG BUNDLE_WITHOUT
ARG BUNDLE_DEPLOYMENT

LABEL maintainer='pglombardo@hey.com'

# install only runtime packages (removed build-related packages)
RUN apk add --no-cache \
    bash \
    curl \
    libc6-compat \
    libpq \
    mariadb-connector-c \
    nodejs \
    tzdata \
    yarn \
    jemalloc

# Create a user and group to run the application
ARG UID=1000
ARG GID=1000

ENV LC_CTYPE=UTF-8 LC_ALL=en_US.UTF-8
ENV APP_ROOT=/opt/PasswordPusher
WORKDIR ${APP_ROOT}
ENV RACK_ENV=production RAILS_ENV=production
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2

RUN addgroup -g "${GID}" pwpusher \
  && adduser -D -u "${UID}" -G pwpusher pwpusher \
  && chown -R pwpusher:pwpusher ${APP_ROOT}

# Set a default secret_key_base
# For those self-hosting this app, you should
# generate your own secret_key_base and set it
# in your environment.
# 1. Generate a secret_key_base value with:
#    bundle exec rails secret
# 2. Set the secret_key_base in your environment:
#    SECRET_KEY_BASE=<value>
ENV SECRET_KEY_BASE=783ff1544b9612d8bceb8e26a0bab0cf22543eec658a498e7ef9e1d617976f960092005c8a54cb588759dc6dd8fd054bc4eca4a94dd7b96c6efda4a14a01bfbd

COPY --from=build-env --chown=pwpusher:pwpusher ${APP_ROOT} ${APP_ROOT}

RUN bundle config set without "${BUNDLE_WITHOUT}" \
    && bundle config set deployment "${BUNDLE_DEPLOYMENT}"

# Copy entrypoints inside container
COPY containers/docker/entrypoint.sh /usr/local/bin/docker-entrypoint
COPY containers/docker/worker-entrypoint.sh /usr/local/bin/docker-worker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-worker-entrypoint

USER pwpusher
EXPOSE 80 443 5100
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
