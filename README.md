# PasswordPusher

PasswordPusher is a Ruby on Rails application to communicate passwords over the web. Links to passwords expire after a certain number of views and/or time has passed. Hosted at [pwpush.com](http://www.pwpush.com).

## Quick Start

If you want to host PasswordPusher yourself, here are 3 

    git clone git@github.com:pglombardo/PasswordPusher.git
    cd PasswordPusher
    RAILS_ENV=private bundle exec rake db:create db:migrate
    RAILS_ENV=private bundle exec rails server

If you get something like 'Command not found: bundle', then you need to run

    gem install bundler
    
If you get something like 'Command not found: gem', then you need to install Ruby. :)
