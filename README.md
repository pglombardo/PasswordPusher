![Password Pusher Front Page](https://s3-eu-west-1.amazonaws.com/pwpush/pwpush_logo_2014.png)

Password Pusher is an opensource application to communicate passwords over the web. Links to passwords expire after a certain number of views and/or time has passed.

Hosted at [pwpush.com](https://pwpush.com) but you can also easily run your own instance internally on Docker, Kubernetes, OpenShift or on Heroku with just a few steps.

[Follow Password Pusher on Twitter](https://twitter.com/pwpush) for the latest news, updates and changes.

[![CircleCI](https://circleci.com/gh/pglombardo/PasswordPusher/tree/master.svg?style=svg)](https://circleci.com/gh/pglombardo/PasswordPusher/tree/master)

# 💾 Running your own Instance of Password Pusher


## On Heroku

One click deploy to [Heroku Cloud](https://www.heroku.com) without having to set up servers.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/pglombardo/PasswordPusher)

_This option will deploy a production PasswordPusher instance backed by a postgres database to Heroku.  As is monthly cost: $0._

## On Docker

Docker images of Password Pusher are available on [Docker hub](https://hub.docker.com/u/pglombardo).

**➜ ephemeral**

    docker run -d -p "5000:5000" pglombardo/pwpush-ephemeral:latest

[Learn more](https://github.com/pglombardo/PasswordPusher/tree/master/containerization#pwpush-ephemeral)

**➜ using an External Postgres Database**

    docker run -d -p "5000:5000" pglombardo/pwpush-postgres:latest

[Learn more](https://github.com/pglombardo/PasswordPusher/tree/master/containerization#pwpush-postgres-external-database)

## With Docker Compose

Included in this repository is `containerization/pwpush-postgres/docker-compose.yaml` which can be used by simply running:

    docker-compose up -d
    docker-compose down

[Learn more](https://github.com/pglombardo/PasswordPusher/tree/master/containerization#pwpush-postgres)

## On Kubernetes

We currently don't supply a prebuilt Kubernetes YAML file yet but you can deploy the above Docker images using [this documentation](https://docs.docker.com/get-started/kube-deploy/).

## On Microsoft Azure

See [this blog post](https://tamethe.cloud/pwpush-host-your-own-using-azure-containers/) on how to deploy Password Pusher to Azure by Craig McLaren.

## On OpenShift

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

* The [Password Pusher Alfred Workflow](http://www.packal.org/workflow/passwordpusher) for Mac users.

* [Kamil Procyszyn](https://twitter.com/kprocyszyn/status/970413009511251968) put together a nice [PowerShell script](https://github.com/kprocyszyn/tools/blob/master/Get-PasswordLink/Get-PasswordLink.ps1) for Password Pusher.

* [lnfnunes](https://github.com/lnfnunes) created a [NodeJS CLI](https://github.com/lnfnunes/pwpush-cli) wrapper for Password Pusher to be easily used in the terminal.

* [CLI written in Python](https://github.com/abkierstein/pwpush) that uses pwpush.com as a backend

* [quasarj](https://github.com/quasarj) created a [django application](https://github.com/quasarj/projectgiraffe) based off of Password Pusher

