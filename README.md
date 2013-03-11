# PasswordPusher

PasswordPusher is a Ruby on Rails application to communicate passwords over the web. Links to passwords expire after a certain number of views and/or time has passed. Hosted at [pwpush.com](http://www.pwpush.com).

I previously posted this project on [Reddit](http://www.reddit.com/r/sysadmin/comments/pfda0/do_you_email_out_passwords_i_wrote_this_utility/) which provided some great feedback - most of which has been implemented.

## Note for Existing Users

*If you're already hosting PasswordPusher yourself, the latest source has all the updates required to address the recent Ruby security issues.  Make sure to do a periodic `git pull` from time to time to always get the latest updates.*

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

### To change the front page default values (days and views expiration)

You can select default, min and max values for "expire after days" and "expire after views" by changing the values in `config/environment.rb`:

    # Controls the "Expire After Days" form settings in Password#new
    EXPIRE_AFTER_DAYS_DEFAULT = 30
    EXPIRE_AFTER_DAYS_MIN = 1
    EXPIRE_AFTER_DAYS_MAX = 90

    # Controls the "Expire After Views" form settings in Password#new
    EXPIRE_AFTER_VIEWS_DEFAULT = 10
    EXPIRE_AFTER_VIEWS_MIN = 1
    EXPIRE_AFTER_VIEWS_MAX = 100

These values are also used in the Password controller range checking code.

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

### How to switch to another backend database

Which database the application uses is specified in `config/database.yml`.  The default configuration has these values for the `private` environment:

    base: &base 
      adapter: sqlite3
      timeout: 5000

    private:
      database: db/private.sqlite3
      <<: *base
    
If you wanted to switch to the postgres database, you would replace the `private` block with something similar to the following:

    private: 
      adapter: postgresql
      database: yourdbname
      username: yourdbusername
      password: yourdbpassword
      pool: 5
      timeout: 5000
      encoding: utf8
      reconnect: false

or for mysql:

    private: 
      adapter: mysql
      database: yourdbname
      username: yourdbusername
      password: yourdbpassword
      pool: 5
      encoding: utf8

For more detailed instructions, see the Ruby on Rails documentation on [configuring a database](http://guides.rubyonrails.org/getting_started.html#configuring-a-database).

Note that you will also need to add in the proper database driver gem to your `Gemfile` by simply adding

    gem "pg"

or

    gem "mysql"

and then running `bundle install`.

## Credits

Thanks to [Kasper 'kapöw' Grubbe](https://github.com/kap0w) for the [JSON POST fix](https://github.com/pglombardo/PasswordPusher/pull/3).

## See Also

[quasarj]() created a [django application](https://github.com/quasarj/projectgiraffe) based off of PasswordPusher

[phanaster](https://github.com/phanaster) created a [Coupon Pushing application](https://github.com/phanaster/cpsh.me) ([cpsh.me](http://cpsh.me/)) based off of PasswordPusher

[bemosior](https://github.com/bemosior) put together a PHP port of PasswordPusher: [PHPasswordPusher](https://github.com/bemosior/PHPasswordPusher)


