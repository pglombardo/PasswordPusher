# Setting global arguments
ARG BUNDLE_WITHOUT=development:test
ARG BUNDLE_DEPLOYMENT=true

FROM ruby:3.4.8-alpine AS build-env

# include global args
ARG BUNDLE_WITHOUT
ARG BUNDLE_DEPLOYMENT

LABEL org.opencontainers.image.authors='pglombardo@hey.com'

# Required build packages - install in single layer for better caching
RUN apk update && apk add --no-cache \
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
ENV RACK_ENV=production RAILS_ENV=production

WORKDIR ${APP_ROOT}

# Copy dependency files first for better layer caching
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies - this layer will be cached unless Gemfile changes
RUN bundle config set without "${BUNDLE_WITHOUT}" \
    && bundle config set deployment "${BUNDLE_DEPLOYMENT}" \
    && bundle install \
    && rm -rf vendor/bundle/ruby/*/cache \
    && rm -rf vendor/bundle/ruby/*/bundler/gems/*/.git \
    && find vendor/bundle/ruby/*/gems/ -name "*.c" -delete \
    && find vendor/bundle/ruby/*/gems/ -name "*.o" -delete

# Copy Node.js dependency files
COPY package.json yarn.lock ./

# Install Node.js dependencies - this layer will be cached unless package.json changes
RUN yarn install --frozen-lockfile

# Copy source code - this should be done as late as possible
COPY ./ ${APP_ROOT}/

# Build assets - this layer will be rebuilt when source code changes
RUN yarn build

# SECRET_KEY_BASE must be set at runtime via environment variable
# Do NOT hardcode secrets in Docker images for security reasons.
# Users should generate their own secret_key_base:
#    bundle exec rails secret
# Then set it when running the container:
#    docker run -e SECRET_KEY_BASE=<your-secret> ...

# Precompile bootsnap cache only for amd64 architecture
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      SECRET_KEY_BASE_DUMMY=1 bundle exec bootsnap precompile --gemfile && \
      SECRET_KEY_BASE_DUMMY=1 bundle exec bootsnap precompile app/ lib/ ; \
    else \
      echo "Skipping bootsnap precompilation for $TARGETARCH" ; \
    fi

# Precompile Rails assets - this layer will be rebuilt when assets change
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

RUN rm -rf tmp/cache tmp/pids tmp/sockets app/assets/images/features

################## Build done ##################

FROM ruby:3.4.8-alpine

# include global args
ARG BUNDLE_WITHOUT
ARG BUNDLE_DEPLOYMENT

LABEL maintainer='pglombardo@hey.com'

# Install runtime packages in single layer for better caching
RUN apk update && apk add --no-cache \
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

# Set environment variables
ENV LC_CTYPE=UTF-8 LC_ALL=en_US.UTF-8
ENV APP_ROOT=/opt/PasswordPusher
ENV RACK_ENV=production RAILS_ENV=production
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2

WORKDIR ${APP_ROOT}

# Create user and set permissions in single layer
RUN addgroup -g "${GID}" pwpusher \
  && adduser -D -u "${UID}" -G pwpusher pwpusher

# SECRET_KEY_BASE must be set at runtime via environment variable
# The entrypoint script will validate or generate one if missing

# Copy application from build stage
COPY --from=build-env --chown=pwpusher:pwpusher ${APP_ROOT} ${APP_ROOT}

# Configure bundle for production
RUN bundle config set without "${BUNDLE_WITHOUT}" \
    && bundle config set deployment "${BUNDLE_DEPLOYMENT}"

# Make sure that the storage directory exists
RUN mkdir -p ${APP_ROOT}/storage/db && chown -R pwpusher:pwpusher ${APP_ROOT}/storage

# Copy and setup entrypoints in single layer
COPY containers/docker/entrypoint.sh /usr/local/bin/docker-entrypoint
COPY containers/docker/worker-entrypoint.sh /usr/local/bin/docker-worker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint /usr/local/bin/docker-worker-entrypoint

# Clean up unnecessary files
RUN rm -rf ${APP_ROOT}/.do \
      ${APP_ROOT}/.github \
      ${APP_ROOT}/app.json \
      ${APP_ROOT}/bin/move_up_stable_tag.sh \
      ${APP_ROOT}/containers \
      ${APP_ROOT}/test \
      ${APP_ROOT}/ct.yaml

RUN touch /opt/PasswordPusher/.env.production && chown pwpusher:pwpusher /opt/PasswordPusher/.env.production

USER pwpusher
EXPOSE 80 443 5100
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
