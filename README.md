![Password Pusher Front Page](https://s3-eu-west-1.amazonaws.com/pwpush/pwpush_logo_2014.png)

PasswordPusher is an opensource application to communicate passwords over the web. Links to passwords expire after a certain number of views and/or time has passed. 

Hosted at [pwpush.com](https://pwpush.com) but you can also easily run your own instance internally on Docker, Kubernetes, OpenShift or on Heroku with just a few steps.

[Follow PasswordPusher on Twitter](https://twitter.com/pwpush) for the latest news, updates and changes.

[![CircleCI](https://circleci.com/gh/pglombardo/PasswordPusher/tree/master.svg?style=svg)](https://circleci.com/gh/pglombardo/PasswordPusher/tree/master)

# 💾 Running your own Instance of PasswordPusher


## Heroku

One click deploy to Heroku and get a fully configured running private instance of PasswordPusher immediately.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/pglombardo/PasswordPusher)

## Docker

Docker images of PasswordPusher are available on [Docker hub](https://hub.docker.com/u/pglombardo).

### Ephemeral

    docker run -d -p "5000:5000" pglombardo/pwpush-ephemeral:latest

[Learn more](https://github.com/pglombardo/PasswordPusher/tree/master/containerization#pwpush-ephemeral)


### With an External Postgres Database

    docker run -d -p "5000:5000" pglombardo/pwpush-postgres:latest
    
This container uses a default database URL of:

    DATABASE_URL=postgresql://passwordpusher_user:passwordpusher_passwd@postgres:5432/passwordpusher_db
    
You can either configure your PostgreSQL server to use these credentials or override the env var in the command line:

    docker run -d -p "5000:5000" -e "DATABASE_URL=postgresql://user:passwd@postgres:5432/my_db" pglombardo/pwpush-postgres:latest
    
_Note: Providing a postgres password on the command line is far less than ideal_

Lastly, you can also rebuild the container image from Dockerfile.  See the `containerization` folder.

[Learn more](https://github.com/pglombardo/PasswordPusher/tree/master/containerization#pwpush-postgres-external-database)

### Docker Compose

Included in this repository is `containerization/pwpush-postgres/docker-compose.yaml` which can be used by simply running:

    docker-compose up -d
    docker-compose down

[Learn more](https://github.com/pglombardo/PasswordPusher/tree/master/containerization#pwpush-postgres)

PasswordPusher can be deployed to [Kubernetes](https://kubernetes.io/), [OpenShift](https://openshift.com/) or any [Docker](https://www.docker.com/) host.

See the [containerization directory](https://github.com/pglombardo/PasswordPusher/tree/master/containerization) for details.  Docker images hosted in [docker.io/r/pglombardo](https://hub.docker.com/r/pglombardo/).

## OpenShift

See our [OpenShift documentation](https://github.com/pglombardo/PasswordPusher/tree/master/containerization#pwpush-openshift).

## From Source

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

# 📼 Credits

Thanks to:

* [@sfarosu](https://github.com/sfarosu) for [contributing](https://github.com/pglombardo/PasswordPusher/pull/82) the Docker, Kubernetes & OpenShift container support.

* [@iandunn](https://github.com/iandunn) for better password form security.

* [Kasper 'kapöw' Grubbe](https://github.com/kaspergrubbe) for the [JSON POST fix](https://github.com/pglombardo/PasswordPusher/pull/3).

* [JarvisAndPi](http://www.reddit.com/user/JarvisAndPi) for the favicon design

# 📡 See Also

* I previously posted this project on [Reddit](http://www.reddit.com/r/sysadmin/comments/pfda0/do_you_email_out_passwords_i_wrote_this_utility/) which provided some great feedback - most of which has been implemented.

* The [PasswordPusher Alfred Workflow](http://www.packal.org/workflow/passwordpusher) for Mac users.

* [Kamil Procyszyn](https://twitter.com/kprocyszyn/status/970413009511251968) put together a nice [PowerShell script](https://github.com/kprocyszyn/tools/blob/master/Get-PasswordLink/Get-PasswordLink.ps1) for Password Pusher.

* [lnfnunes](https://github.com/lnfnunes) created a [NodeJS CLI](https://github.com/lnfnunes/pwpush-cli) wrapper for Password Pusher to be easily used in the terminal.

* [quasarj](https://github.com/quasarj) created a [django application](https://github.com/quasarj/projectgiraffe) based off of PasswordPusher

* [phanaster](https://github.com/phanaster) created a [Coupon Pushing application](https://github.com/phanaster/cpsh.me) based off of PasswordPusher

* [bemosior](https://github.com/bemosior) put together a PHP port of PasswordPusher: [PHPasswordPusher](https://github.com/bemosior/PHPasswordPusher)


