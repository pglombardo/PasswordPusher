FROM docker.io/ubuntu:18.04

# Use the following 2 env variables if you need proxy support in your environment
#ENV https_proxy=http://10.0.2.2:3128
#ENV http_proxy=http://10.0.2.2:3128

ENV APP_ROOT=/opt/PasswordPusher
ENV PATH=${APP_ROOT}:${PATH} HOME=${APP_ROOT}
RUN ln -fs /usr/share/zoneinfo/Europe/Paris > /etc/localtime
RUN apt-get update -qq && \
    apt-get install -y --assume-yes build-essential git curl ruby2.5 ruby2.5-dev tzdata sqlite3 ruby-sqlite3 libsqlite3-dev zlib1g-dev && \
    cd /opt && \
    git clone https://github.com/pglombardo/PasswordPusher.git && \
    touch ${APP_ROOT}/log/private.log && \
    cd ${APP_ROOT} && \
    gem install bundler && \
    gem install thor && \
    chown -R 1001:root ${APP_ROOT}

EXPOSE 5000

USER 1001
WORKDIR ${APP_ROOT}
RUN bundle install --without development production test --deployment && \
    bundle exec rake assets:precompile && \
    RAILS_ENV=private bundle exec rake db:setup

USER root
RUN chmod -R u+x ${APP_ROOT} && \
    chgrp -R 0 ${APP_ROOT} && \
    chmod -R g=u ${APP_ROOT} /etc/passwd

USER 1001
ENTRYPOINT [ "bundle", "exec", "foreman", "start", "internalweb" ]
