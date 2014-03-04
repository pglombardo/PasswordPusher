![Password Pusher Front Page](https://s3-eu-west-1.amazonaws.com/pwpush/Password+Pusher+Front+Page.png)

PasswordPusher is a Ruby on Rails application to communicate passwords over the web. Links to passwords expire after a certain number of views and/or time has passed. Hosted at [pwpush.com](https://pwpush.com) (but you can also [easily run your own instance](#quick-start---heroku)).

I previously posted this project on [Reddit](http://www.reddit.com/r/sysadmin/comments/pfda0/do_you_email_out_passwords_i_wrote_this_utility/) which provided some great feedback - most of which has been implemented.

## Note for Existing Users

If you're already hosting your own private instance of PasswordPusher, make sure to do a periodic `git pull` from time to time to always get the latest updates. 

You can always checkout out the [latest commits](https://github.com/pglombardo/PasswordPusher/commits/master) to see what's been updated recently.

## Quick Start - Heroku

You can quickly host your own instance of Password Pusher on [Heroku](https://www.heroku.com) by just pasting the following commands:
```sh
# Hopefully you're not running this as root (you shouldn't be)
export PWPUSH_APP_NAME="pwpush-`whoami`"

# Clone the PasswordPusher Repo locally
git clone git@github.com:pglombardo/PasswordPusher.git
cd PasswordPusher

# Create the actual Heroku app and add the postgres DB addon
heroku apps:create $PWPUSH_APP_NAME
heroku addons:add heroku-postgresql
heroku labs:enable user-env-compile
heroku config:add BUNDLE_WITHOUT="development:test:private"

# Push the code to your new Heroku app
git push heroku master

# Setup the PasswordPusher database
heroku run bundle exec rake db:setup

echo "See your new PasswordPusher instance at https://$PWPUSH_APP_NAME.herokuapp.com"
```
Notes:

* If you haven't used Heroku before, you'll need a [Heroku account](https://id.heroku.com/signup) and the [Heroku Toolbelt](https://toolbelt.heroku.com/) installed first.
* To change the Heroku app name (and resulting URL), change the value of PWPUSH_APP_NAME

## Quick Start - Private Server

If you want to host PasswordPusher yourself:

```sh
git clone git@github.com:pglombardo/PasswordPusher.git
cd PasswordPusher
bundle install --without development test --deployment
export RAILS_ENV=private
bundle exec rake db:create db:migrate
bundle exec rails server -p 80
```
    
Then view the site @ [http://localhost/](http://localhost/)

### Potential Private Server Quick Start Errors

#### Command not found: bundle

If you get something like `Command not found: bundle`, then you need to run

    gem install bundler

_If you get something like 'Command not found: gem', then you need to install Ruby. :)_

#### SQLite3

If the 'bundle install' fails with 'checking for sqlite3.h... no', you have to install the sqlite3 packages for your operating system.  For Ubuntu, the command is:

```sh
sudo apt-get install sqlite3 ruby-sqlite3 libsqlite3-ruby libsqlite3-dev
```

## Other Information

* How to use the [Password API](https://github.com/pglombardo/PasswordPusher/wiki/Password-API)
* How to [Change the Front Page Default Values](https://github.com/pglombardo/PasswordPusher/wiki/Changing-the-Front-Page-Default-Values)
* How to [Switch to Production Environment](https://github.com/pglombardo/PasswordPusher/wiki/Switch-to-Production-Environment)
* How to [Switch to Another Backend Database](https://github.com/pglombardo/PasswordPusher/wiki/Switch-to-Another-Backend-Database)

### Tip

SQLite3 is provided by default for a quick and easy setup of the application.

If you plan to use PasswordPusher internally at your organization and expect to have multiple users concurrently creating passwords, it's advised to move away from SQLite3 as it doesn't support write concurrency and errors will occur.  

For example, on [https://pwpush.com](https://pwpush.com), I run the application with a Postgres database.

*Initiated from [this discussion](http://www.reddit.com/r/sysadmin/comments/yxps8/passwordpusher_best_way_to_deliver_passwords_to/c5zwts9) on reddit.*

## Credits

Thanks to:

* [@iandunn](https://github.com/iandunn) for better password form security.

* [Kasper 'kapöw' Grubbe](https://github.com/kaspergrubbe) for the [JSON POST fix](https://github.com/pglombardo/PasswordPusher/pull/3).

* [JarvisAndPi](http://www.reddit.com/user/JarvisAndPi) for the favicon design

## See Also

[quasarj](https://github.com/quasarj) created a [django application](https://github.com/quasarj/projectgiraffe) based off of PasswordPusher

[phanaster](https://github.com/phanaster) created a [Coupon Pushing application](https://github.com/phanaster/cpsh.me) ([cpsh.me](http://cpsh.me/)) based off of PasswordPusher

[bemosior](https://github.com/bemosior) put together a PHP port of PasswordPusher: [PHPasswordPusher](https://github.com/bemosior/PHPasswordPusher)


