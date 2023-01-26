# pwpush-ephemeral
FROM ruby:3.2-slim AS build-env

LABEL maintainer='pglombardo@hey.com'

RUN apt-get update && apt-get install -y curl ca-certificates gnupg

# Required to get the Node.js yarn tool
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Required packages
RUN apt-get update && apt-get install -qq -y --assume-yes bash build-essential apt-utils git tzdata nodejs yarn zlib1g-dev libsqlite3-0 libsqlite3-dev

ENV APP_ROOT=/opt/PasswordPusher PATH=${APP_ROOT}:${PATH} HOME=${APP_ROOT}

RUN mkdir -p ${APP_ROOT}
COPY ./ ${APP_ROOT}/

WORKDIR ${APP_ROOT}







RUN gem install bundler


ENV RACK_ENV=private RAILS_ENV=private RAILS_SERVE_STATIC_FILES=true

RUN bundle config set without 'development production test' \
    && bundle config set deployment 'true' \
    && bundle install


RUN bundle exec rails assets:precompile && bundle exec rake db:setup

# Removing unneccesary files/directories
RUN rm -rf node_modules tmp/cache vendor/assets spec \
    && rm -rf vendor/bundle/ruby/*/cache/*.gem \
    && find vendor/bundle/ruby/*/gems/ -name "*.c" -delete \
    && find vendor/bundle/ruby/*/gems/ -name "*.o" -delete

################## Build done ##################

FROM ruby:3.2-slim

LABEL maintainer='pglombardo@hey.com'

# install packages
RUN apt-get update \
    && apt-get upgrade -y --assume-yes 


# Create a user and group to run the application
ARG UID=1000
ARG GID=1000

RUN groupadd -g "${GID}" pwpusher \
  && useradd --create-home --no-log-init -u "${UID}" -g "${GID}" pwpusher

ENV APP_ROOT=/opt/PasswordPusher PATH=${APP_ROOT}:${PATH} HOME=${APP_ROOT}
ENV RACK_ENV=private RAILS_ENV=private RAILS_SERVE_STATIC_FILES=true

WORKDIR ${APP_ROOT}

RUN mkdir -p ${APP_ROOT} && chown -R pwpusher:pwpusher ${APP_ROOT}
COPY --from=build-env --chown=pwpusher:pwpusher ${APP_ROOT} ${APP_ROOT}

RUN bundle config set without 'development production test' && bundle config set deployment 'true'

USER pwpusher
EXPOSE 5100
ENTRYPOINT ["containers/docker/pwpush-ephemeral/entrypoint.sh"]
