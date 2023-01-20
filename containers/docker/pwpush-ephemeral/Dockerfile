# pwpush-ephemeral
FROM ruby:3.2-slim

LABEL maintainer='pglombardo@hey.com'

# Create a user and group to run the application
ARG UID=1000
ARG GID=1000

RUN groupadd -g "${GID}" pwpusher \
  && useradd --create-home --no-log-init -u "${UID}" -g "${GID}" pwpusher

ENV APP_ROOT=/opt/PasswordPusher
ENV PATH=${APP_ROOT}:${PATH} HOME=${APP_ROOT}

RUN apt-get update && apt-get install -y curl ca-certificates gnupg

# Required to get the Node.js yarn tool
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Required packages
RUN apt-get update && apt-get install -qq -y --assume-yes build-essential apt-utils libpq-dev git curl tzdata libsqlite3-0 libsqlite3-dev zlib1g-dev nodejs yarn

RUN mkdir -p ${APP_ROOT} && chown -R pwpusher:pwpusher ${APP_ROOT}
COPY --chown=pwpusher:pwpusher ./ ${APP_ROOT}/
USER pwpusher

EXPOSE 5100

RUN gem install bundler

WORKDIR ${APP_ROOT}

ENV RACK_ENV=private
ENV RAILS_ENV=private

RUN bundle config set without 'development production test'
RUN bundle config set deployment 'true'

RUN bundle install
RUN yarn install
RUN bundle exec rails assets:precompile
RUN bundle exec rake db:setup

ENTRYPOINT ["containers/docker/pwpush-ephemeral/entrypoint.sh"]
