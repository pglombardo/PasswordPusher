![Password Pusher Front Page](https://s3-eu-west-1.amazonaws.com/pwpush/pwpush_logo_2014.png)

PasswordPusher is an opensource Ruby on Rails application to communicate passwords over the web. Links to passwords expire after a certain number of views and/or time has passed. 

Hosted at [pwpush.com](https://pwpush.com) but you can also easily run your own instance internally on Docker, Kubernetes, OpenShift or on Heroku with just a few steps.

I previously posted this project on [Reddit](http://www.reddit.com/r/sysadmin/comments/pfda0/do_you_email_out_passwords_i_wrote_this_utility/) which provided some great feedback - most of which has been implemented.

[![Build Status](https://travis-ci.org/pglombardo/PasswordPusher.svg?branch=master)](https://travis-ci.org/pglombardo/PasswordPusher)


## See Also

The [PasswordPusher Alfred Workflow](http://www.packal.org/workflow/passwordpusher) for Mac users.

## Deploy to Heroku

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/pglombardo/PasswordPusher)

## Deploy in Containers

PasswordPusher can be deployed to [Kubernetes](https://kubernetes.io/), [OpenShift](https://openshift.com/) or any [Docker](https://www.docker.com/) host.

See the [containerization directory](https://github.com/pglombardo/PasswordPusher/tree/master/containerization) for details.  Docker images hosted in [docker.io/r/pglombardo](https://hub.docker.com/r/pglombardo/).

## Deploy Manually

Make sure you have git and Ruby installed and then:

```sh
git clone git@github.com:pglombardo/PasswordPusher.git
cd PasswordPusher
gem install bundler
bundle install --without development production test --deployment
bundle exec rake assets:precompile
RAILS_ENV=private bundle exec rake db:setup
foreman start internalweb
```

Then view the site @ [http://localhost:5000/](http://localhost:5000/).

_Note: You can change the listening port by modifying the
[Procfile](https://github.com/pglombardo/PasswordPusher/blob/master/Procfile#L2)_

### Troubleshooting

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

With the internal deploy process described above, SQLite3 is provided by default for a quick and easy setup of the application.

If you plan to use PasswordPusher internally at your organization and expect to have multiple users concurrently creating passwords, it's advised to move away from SQLite3 as it doesn't support write concurrency and errors will occur.  

For example, on [https://pwpush.com](https://pwpush.com), I run the application with a Postgres database.

*Initiated from [this discussion](http://www.reddit.com/r/sysadmin/comments/yxps8/passwordpusher_best_way_to_deliver_passwords_to/c5zwts9) on reddit.*

See How to [Switch to Another Backend Database](https://github.com/pglombardo/PasswordPusher/wiki/Switch-to-Another-Backend-Database) for details.

## Note for Existing Users

If you're already hosting your own private instance of PasswordPusher, make sure to do a periodic `git pull` from time to time to always get the latest updates. 

You can always checkout out the [latest commits](https://github.com/pglombardo/PasswordPusher/commits/master) to see what's been updated recently.

## Credits

Thanks to:

* [@sfarosu](https://github.com/sfarosu) for [contributing](https://github.com/pglombardo/PasswordPusher/pull/82) the Docker, Kubernetes & OpenShift container support.

* [@iandunn](https://github.com/iandunn) for better password form security.

* [Kasper 'kapöw' Grubbe](https://github.com/kaspergrubbe) for the [JSON POST fix](https://github.com/pglombardo/PasswordPusher/pull/3).

* [JarvisAndPi](http://www.reddit.com/user/JarvisAndPi) for the favicon design

## See Also

[Kamil Procyszyn](https://twitter.com/kprocyszyn/status/970413009511251968) put together a nice [PowerShell script](https://github.com/kprocyszyn/tools/blob/master/push-pwpush.ps1) for Password Pusher.

[lnfnunes](https://github.com/lnfnunes) created a [NodeJS CLI](https://github.com/lnfnunes/pwpush-cli) wrapper for Password Pusher to be easily used in the terminal.

[quasarj](https://github.com/quasarj) created a [django application](https://github.com/quasarj/projectgiraffe) based off of PasswordPusher

[phanaster](https://github.com/phanaster) created a [Coupon Pushing application](https://github.com/phanaster/cpsh.me) based off of PasswordPusher

[bemosior](https://github.com/bemosior) put together a PHP port of PasswordPusher: [PHPasswordPusher](https://github.com/bemosior/PHPasswordPusher)


