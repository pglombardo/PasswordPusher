# PasswordPusher

PasswordPusher is a Ruby on Rails application to communicate passwords over the web. Links to passwords expire after a certain number of views and/or time has passed. Hosted at [pwpush.com](http://www.pwpush.com).

I previously posted this project on [Reddit](http://www.reddit.com/r/sysadmin/comments/pfda0/do_you_email_out_passwords_i_wrote_this_utility/) which provided some great feedback - most of which has been implemented.

## Quick Start

If you want to host PasswordPusher yourself:

    git clone git@github.com:pglombardo/PasswordPusher.git
    cd PasswordPusher
    bundle install --without development test --deployment
    export RAILS_ENV=private
    bundle exec rake db:create db:migrate
    bundle exec rails server
    
Then view the site @ [http://localhost:3000](http://localhost:3000)

If you want to run the site on a different port, use the -p parameter.

    bundle exec rails server -p 80

## Potential Quick Start Errors

### Command not found: bundle

If you get something like 'Command not found: bundle', then you need to run

    gem install bundler

### Command not found: gem    

If you get something like 'Command not found: gem', then you need to install Ruby. :)

### SQLite3

If the 'bundle install' fails with 'checking for sqlite3.h... no', you have to install the sqlite3 packages for your operating system.  For Ubuntu, the command is:

    sudo apt-get install sqlite3 ruby-sqlite3 libsqlite3-ruby libsqlite3-dev
    
## Other Information

### If you want to switch to 'production' environment...

Remember to precompile your assets before starting the server with:

    export RAILS_ENV=production
    bundle exec rake assets:precompile

If you don't do this in 'production' environment, you will get an error similar to:

    We're sorry, but something went wrong.
    
and in your logs:

    ActionView::Template::Error (application.css isn't precompiled):
