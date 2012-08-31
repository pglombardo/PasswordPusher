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

## API

You can generate passwords through an API, if you want to automate creation, it is done by hitting the password action with a POST-request. In the development environment you can use this address: http://127.0.0.1:3000/passwords.json

And you will have to send these POST variables:

    password[payload]: test 
    password[expire_after_days]: 60
    password[expire_after_views]: 1337

You can test it in your browsers javascript console by going to the frontpage of Password Pusher and type:

    $.post('http://127.0.0.1:3000/passwords.json',{ 'password[payload]': 'test', 'password[expire_after_days]': '60', 'password[expire_after_views]': '1337' }, function(data) { alert(data.url_token) } )

Or do it with curl:

    curl -d -X POST --data "password[payload]=payload&password[expire_after_days]=60&password[expire_after_views]=1337" http://127.0.0.1:3000/passwords.json

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
    
### Tip

If you plan to use PasswordPusher internally at your organization and expect to have multiple users concurrently creating passwords, it's advised to move away from SQLite3 as it doesn't support write concurrency and errors will occur.  

SQLite3 is provided by default for a quick and easy setup of the application.

For example, on [https://pwpush.com](https://pwpush.com), I run the application with a Postgres database.

*Initiated from [this discussion](http://www.reddit.com/r/sysadmin/comments/yxps8/passwordpusher_best_way_to_deliver_passwords_to/c5zwts9) on reddit.*

## Credits

Thanks to [Kasper 'kapöw' Grubbe](https://github.com/kap0w) for the [JSON POST fix](https://github.com/pglombardo/PasswordPusher/pull/3).

## See Also

[quasarj]() created a [django application](https://github.com/quasarj/projectgiraffe) based off of PasswordPusher

[phanaster](https://github.com/phanaster) created a [Coupon Pushing application](https://github.com/phanaster/cpsh.me) ([cpsh.me](http://cpsh.me/)) based off of PasswordPusher

[bemosior](https://github.com/bemosior) put together a PHP port of PasswordPusher: [PHPasswordPusher](https://github.com/bemosior/PHPasswordPusher)


