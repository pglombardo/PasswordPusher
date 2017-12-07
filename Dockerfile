FROM ruby:2.4.2-onbuild
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs openssh-client git vim zip curl
RUN mkdir /pwpush
WORKDIR /pwpush
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install --jobs 20 --retry 5
COPY . ./
EXPOSE 3000

# To use as temporary preview of the app.  Not suitable for production
# as the database is recreated from scratch on each docker image boot.
ENV RAILS_ENV=private
CMD bundle exec rake db:setup && bundle exec rails server

# Other entries that are useful when debugging, testing etc..
#CMD bundle exec rails server -p 8080 -b 0.0.0.0
#CMD bundle exec rails server
#ENV INSTANA_GEM_DEV=true
