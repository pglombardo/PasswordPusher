FROM docker.io/ubuntu:focal

# Use the following 2 env variables if you need proxy support in your environment
#ENV https_proxy=http://10.0.2.2:3128
#ENV http_proxy=http://10.0.2.2:3128

ENV APP_ROOT=/opt/PasswordPusher
ENV PATH=${APP_ROOT}:${PATH} HOME=${APP_ROOT}

RUN ln -fs /usr/share/zoneinfo/Europe/Paris > /etc/localtime
RUN apt-get update -qq && \
    apt-get install -y --assume-yes build-essential libpq-dev git curl ruby2.7 ruby2.7-dev tzdata sqlite3 ruby-sqlite3 libsqlite3-dev zlib1g-dev nodejs yarnpkg && \
    cd /opt && \
    git clone https://github.com/pglombardo/PasswordPusher.git && \
    touch ${APP_ROOT}/log/private.log && \
    cd ${APP_ROOT} && \
    chown -R 1001:root ${APP_ROOT}

EXPOSE 5000

RUN gem update --system
RUN gem install bundler
RUN gem install thor

USER 1001
WORKDIR ${APP_ROOT}

ENV RACK_ENV=private
ENV RAILS_ENV=private
RUN bundle config set without 'development production test'
RUN bundle config set deployment 'true'

RUN bundle install
RUN bundle exec rake assets:precompile
RUN bundle exec rake db:setup

USER root
RUN chmod -R u+x ${APP_ROOT} && \
    chgrp -R 0 ${APP_ROOT} && \
    chmod -R g=u ${APP_ROOT} /etc/passwd

USER 1001
ENTRYPOINT [ "bundle", "exec", "foreman", "start", "internalweb" ]
