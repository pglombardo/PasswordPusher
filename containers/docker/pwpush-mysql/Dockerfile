# pwpush-mysql
FROM ruby:3-slim

LABEL maintainer='pglombardo@hey.com'

# Create a user and group to run the application
ARG UID=1000
ARG GID=1000

RUN groupadd -g "${GID}" pwpusher \
  && useradd --create-home --no-log-init -u "${UID}" -g "${GID}" pwpusher

USER pwpusher

ENV APP_ROOT=/opt/PasswordPusher
ENV PATH=${APP_ROOT}:${PATH} HOME=${APP_ROOT}
ENV DATABASE_URL=mysql2://passwordpusher_user:passwordpusher_passwd@mysql:3306/passwordpusher_db

RUN apt-get update && apt-get install -y curl ca-certificates gnupg

# Required to get the Node.js yarn tool
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Required packages
RUN apt-get update -qq && \
    apt-get install -qq -y --assume-yes build-essential apt-utils git curl tzdata zlib1g-dev nodejs yarn default-libmysqlclient-dev

RUN mkdir -p ${APP_ROOT}
ADD ./ ${APP_ROOT}/

WORKDIR ${APP_ROOT}
EXPOSE 5100

RUN gem install bundler
ENV BUNDLE_GEMFILE=./gemfiles/mysql/Gemfile

ENV RACK_ENV=production
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
RUN bundle config set without 'development private test'
RUN bundle config set deployment 'true'

RUN bundle install
RUN yarn install
RUN bundle exec rails webpacker:compile

ENTRYPOINT ["containers/docker/pwpush-mysql/entrypoint.sh"]
