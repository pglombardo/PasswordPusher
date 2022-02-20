# pwpush-ephemeral
FROM ruby:3.1.0

LABEL maintainer='pglombardo@hey.com'

ENV APP_ROOT=/opt/PasswordPusher
ENV PATH=${APP_ROOT}:${PATH} HOME=${APP_ROOT}

# For the latest yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Required packages
RUN apt-get update -qq && \
    apt-get install -qq -y --assume-yes build-essential apt-utils libpq-dev git curl tzdata libsqlite3-0 libsqlite3-dev zlib1g-dev nodejs yarn && \
    cd /opt && \
    git clone https://github.com/pglombardo/PasswordPusher.git && \
    touch ${APP_ROOT}/log/private.log

EXPOSE 5100

RUN gem install bundler

WORKDIR ${APP_ROOT}

ENV RACK_ENV=private
ENV RAILS_ENV=private

RUN bundle config set without 'development production test'
RUN bundle config set deployment 'true'

RUN bundle install
RUN yarn install
RUN bundle exec rails webpacker:compile
RUN bundle exec rake db:setup

ENTRYPOINT ["bundle", "exec", "puma", "-C", "config/puma.rb", "-e", "private"]
