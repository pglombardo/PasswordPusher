<div align="center">

![Password Pusher Front Page](https://pwpush.s3.eu-west-1.amazonaws.com/pwpush-horizontal-logo.png)

__Simple & Secure Password Sharing with Auto-Expiration of Shared Items__

[![](https://badgen.net/twitter/follow/pwpush)](https://twitter.com/pwpush)
![](https://badgen.net/github/stars/pglombardo/PasswordPusher)
[![](https://badgen.net/uptime-robot/month/m789048867-17b5770ccd78208645662f1f)](https://stats.uptimerobot.com/6xJjNtPr93)
[![](https://badgen.net/docker/pulls/pglombardo/pwpush-ephemeral)](https://hub.docker.com/repositories)

[![Github CI](https://github.com/pglombardo/PasswordPusher/actions/workflows/ruby-tests.yml/badge.svg)](https://github.com/pglombardo/PasswordPusher/actions/workflows/ruby-tests.yml)
[![](https://badgen.net/circleci/github/pglombardo/PasswordPusher)](https://circleci.com/gh/pglombardo/PasswordPusher/tree/master)
[![Dependencies Status](https://img.shields.io/badge/dependencies-up%20to%20date-brightgreen.svg)](https://github.com/pglombardo/pwpush-cli/pulls?utf8=%E2%9C%93&q=is%3Apr%20author%3Aapp%2Fdependabot)
[![Semantic Versions](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--versions-e10079.svg)](https://github.com/pglombardo/pwpush-cli/releases)
[![License](https://img.shields.io/github/license/pglombardo/PasswordPusher)](https://github.com/pglombardo/pwpush/blob/master/LICENSE)

</div>

------

Give your users the tools to be secure by default.

Password Pusher is an opensource application to communicate passwords over the web. Links to passwords expire after a certain number of views and/or time has passed.

Hosted at [pwpush.com](https://pwpush.com) but you can also easily run your own private instance with just a few steps.

* __Easy-to-install:__ Host your own via Docker, a cloud service or just use [pwpush.com](https://pwpush.com)
* __Opensource:__ No blackbox code.  Only trusted, tested and reviewed opensource code.
* __Versatile:__ Push passwords, text, files or URLs that autoexpire and self delete.
* __Audit logging:__ Track and control what you've shared and see who has viewed it.
* __Encrypted storage:__ All sensitive data is stored encrypted and deleted entirely once expired.
* __Host your own:__ Database backed or ephemeral, easily run your own instance isolated from the world.
* __JSON API:__ Raw JSON API available for 3rd party tools or command line via `curl` or `wget`.
* __Command line interface:__ Automate your password distribution with CLI tools or custom scripts.
* __Logins__: Invite your colleagues and track what is pushed and who retrieved it.
* __Internationalized:__ 23 language translations are bundled in.  Easily selectable via UI or URL
* __Themes:__ [26 themes](./Themes.md) bundled in courtesy of Bootswatch.  Select with a simple environment variable.
* __Unbranded delivery page:__ No logos, superfluous text or unrelated links to confuse end users.
* __Customizable:__ Change text and default options via environment variables.
* __Light & dark themes:__  Via CSS @media integration, the default site theme follows your local preferences.
* __Rebrandable:__ Customize the site name, tagline and logo to fit your environment.
* __Custom CSS:__ Bundle in your own custom CSS to add your own design.
* __10 Years Old:__ Password Pusher has securely delivered millions and millions of passwords in its 10 year history.
* __Actively Maintained:__ I happily work for the good karma of the great IT/Security community.
* __Honest Software:__  Opensource written and maintained by [me](https://github.com/pglombardo) with the help of some great contributors.  No organizations, corporations or evil agendas.

💌 --> Sign up for [the newsletter](https://buttondown.email/pwpush?tag=github) to get updates on big releases, security issues, new features, integrations, tips and more.

Password Pusher is also on [on Twitter](https://twitter.com/pwpush), [Gettr](https://gettr.com/user/pwpush) and [on Facebook](https://www.facebook.com/pwpush)

-----

[![](./app/assets/images/features/front-page-thumb.png)](./app/assets/images/features/front-page-large.png)
[![](./app/assets/images/features/audit-log-thumb.png)](./app/assets/images/features/audit-log-large.png)
[![](./app/assets/images/features/secret-url-languages-thumb.png)](./app/assets/images/features/secret-url-languages-large.png)
[![](./app/assets/images/features/password-generator-thumb.png)](./app/assets/images/features/password-generator-large.png)
[![](./app/assets/images/features/dark-theme-thumb.png)](./app/assets/images/features/dark-theme.gif)
[![](./app/assets/images/features/preliminary-step-thumb.png)](./app/assets/images/features/preliminary-step.gif)


# ⚡️ Quickstart

→ Go to [pwpush.com](https://pwpush.com) and try it out.

_or_

→ Run your own instance with one command: `docker run -d -p "5100:5100" pglombardo/pwpush-ephemeral:release` then go to http://localhost:5100

_or_

→ Use one of the [3rd party tools](#3rd-party-tools) that interface with Password Pusher.

# 💾 Run Your Own Instance

_Note: Password Pusher can be largely configured by environment variables so after you pick your deployment method below, make sure to read [the configuration page](Configuration.md).  Take particular attention in setting your own custom encryption key which isn't required but provides the best security for your instance._

## On Docker

Docker images of Password Pusher are available on [Docker hub](https://hub.docker.com/u/pglombardo).

**➜ ephemeral**
_Temporary database that is wiped on container restart._

    docker run -d -p "5100:5100" pglombardo/pwpush-ephemeral:release

[Learn more](https://github.com/pglombardo/PasswordPusher/tree/master/containers/docker#pwpush-ephemeral)

**➜ using an External Postgres Database**
_Postgres database backed instance._

    docker run -d -p "5100:5100" pglombardo/pwpush-postgres:release

[Learn more](https://github.com/pglombardo/PasswordPusher/tree/master/containers/docker#pwpush-postgres)

**➜ using an External MariaDB (MySQL) Database**
_Mariadb database backed instance._

    docker run -d -p "5100:5100" pglombardo/pwpush-mysql:release

[Learn more](https://github.com/pglombardo/PasswordPusher/tree/master/containers/docker#pwpush-mysql)

_Note: The `latest` Docker container tag builds nightly off of the latest code changes and can occasionally be unstable.  Always use the ['release' or version'd tags](https://hub.docker.com/repository/docker/pglombardo/pwpush-ephemeral/tags?page=1&ordering=last_updated) if you prefer more stability in releases._

## With Docker Compose

**➜ One-liner Password Pusher with a Postgres Database**

    curl -s -o docker-compose.yml https://raw.githubusercontent.com/pglombardo/PasswordPusher/master/containers/docker/pwpush-postgres/docker-compose.yml && docker compose up -d

**➜ One-liner Password Pusher with a MariaDB (MySQL) Database**

    curl -s -o docker-compose.yml https://raw.githubusercontent.com/pglombardo/PasswordPusher/master/containers/docker/pwpush-mysql/docker-compose.yml && docker compose up -d

## On Kubernetes

Instructions and explanation of a Kubernetes setup [can be found
here](https://github.com/pglombardo/PasswordPusher/tree/master/containers/kubernetes).

## On Kubernetes with Helm

A basic helm chart with instructions [can be found here](containers/helm/).

## On Microsoft Azure

_There used to be a 3rd party blog post with instructions but it's been deleted.  If anyone has instructions they would like to contribute, it would be greatly appreciated._

See [issue #277](https://github.com/pglombardo/PasswordPusher/issues/277)

## On Heroku

One click deploy to [Heroku Cloud](https://www.heroku.com) without having to set up servers.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/pglombardo/PasswordPusher)

_This option will deploy a production Password Pusher instance backed by a postgres database to Heroku.  Heroku used to offer free dynos but that is [no longer the case](https://blog.heroku.com/next-chapter) from November 28, 2022.  Hosting charges will be incurred._

## On PikaPods

One click deploy to [PikaPods](https://www.pikapods.com/) from $1/month. Start free with $5 welcome credit.

[![Run on PikaPods](https://www.pikapods.com/static/run-button.svg)](https://www.pikapods.com/pods?run=pwpush)

## With Nginx

See the prebuilt [Docker Compose example here](https://github.com/pglombardo/PasswordPusher/tree/master/containers/examples/pwpush-and-nginx).

## From Source

I generally don't suggest building this application from source code for casual use.  The is due to the complexities in the toolset across platforms.  Running from source code is best when you plan to develop the application.

For quick and easy, use the Docker containers instead.

But if you're resolute & brave, continue on!

### Dependencies

* Ruby 3.0 or greater (2.7 may work)
* Recent Node.js stable & Yarn
* Compiler tools: gcc g++ make
* Other: git

### SQLite3 backend

* Make sure to install sqlite3 development libraries: `apt install libsqlite3-dev sqlite3`

```sh
git clone git@github.com:pglombardo/PasswordPusher.git
cd PasswordPusher
gem install bundler

export RAILS_ENV=private

bundle config set with 'sqlite'
bundle config set --local deployment 'true'
bundle install --without development production test
./bin/rails assets:precompile
./bin/rails db:setup
./bin/rails server --environment=private
```

Then view the site @ [http://localhost:5100/](http://localhost:5100/).

### Postgres, MySQL or Mariadb backend

* Make sure to install related database driver development libraries: e.g. postgres-dev or libmariadb-dev

```sh
git clone git@github.com:pglombardo/PasswordPusher.git
cd PasswordPusher
gem install bundler

export RAILS_ENV=production

# Update the following line to point to your Postgres (or MySQL/Mariadb) instance
DATABASE_URL=postgresql://passwordpusher_user:passwordpusher_passwd@postgres:5432/passwordpusher_db

bundle config set with 'postgres' # or 'mysql'
bundle install --without development private test
./bin/rails assets:precompile
./bin/rails db:setup
./bin/rails server --environment=production
```

Then view the site @ [http://localhost:5100/](http://localhost:5100/).


# 🔨 3rd Party Tools

## Command Line Utilities

* The almost official [pwpush-cli](https://github.com/pglombardo/pwpush-cli) (in pre-beta): CLI for Password Pusher with authentication support

* [thekamilpro/kppwpush](https://github.com/thekamilpro/kppwpush): A PowerShell Module available in the [PowerShell Gallery](https://www.powershellgallery.com/packages/KpPwpush/0.0.1).  See the livestream of its creation on [The Kamil Pro's channel](https://www.youtube.com/watch?v=f8_PZOx_KBY&feature=youtu.be).

* [pgarm/pwposh](https://github.com/pgarm/pwposh): a PowerShell module available in the [PowerShell Gallery](https://www.powershellgallery.com/packages/PwPoSh/)

*  [lnfnunes/pwpush-cli](https://github.com/lnfnunes/pwpush-cli): a Node.js based CLI

* [abkierstein/pwpush](https://github.com/abkierstein/pwpush): a Python based CLI

## Libraries & APIs

* [oyale/PwPush-PHP](https://github.com/oyale/PwPush-PHP): a PHP library wrapper to easily push passwords to any Password Pusher instance

## Android Apps

*  [Pushie](https://play.google.com/store/apps/details?id=com.chesire.pushie) by [chesire](https://github.com/chesire)

## Application Integrations

* [Slack: How to Add a Custom Slash Command](https://github.com/pglombardo/PasswordPusher/wiki/PasswordPusher-&-Slack:-Custom-Slash-Command)

* [Unraid Application](https://forums.unraid.net/topic/104128-support-passwordpusher-pwpush-corneliousjd-repo/)

* [Alfred Workflow](http://www.packal.org/workflow/passwordpusher) for Mac users

_See also the [Tools Page on pwpush.com](https://pwpush.com/en/pages/tools)._

# 📡 The Password Pusher API

* [JSON API Documentation](https://pwpush.com/api)
* [Walkthrough & Examples](https://github.com/pglombardo/PasswordPusher/wiki/Password-API)

# 🇮🇹 Internationalization

Password Pusher is currently available in **23 languages** with more languages being added often as volunteers apply.

From within the application, the language is selectable from a language menu.  Out of the box and before any language menu selection is done, the default language for the application is English.

## Changing the Default Language

The default language can be changed by setting an environment variable with the appropriate language code:

    PWP__DEFAULT_LOCALE=es

For more details, a list of supported language codes and further explanation, see the bottom of this [configuration file](https://github.com/pglombardo/PasswordPusher/blob/master/config/settings.yml).

# 🛟 Help Out

[pwpush.com](https://pwpush.com) is hosted on Digital Ocean and is happily paid out of pocket by myself for more than 10 years.

__But you could help out greatly__ by signing up to Digital Ocean with [this link](https://m.do.co/c/f4ea6ef24c13) (and get $200 credit).  In return, Password Pusher gets a helpful hosting credit.

**tldr;** Sign up to Digital Ocean [with this link](https://m.do.co/c/f4ea6ef24c13), **get a $200 credit for free** and help Password Pusher out.

[![DigitalOcean Referral Badge](https://web-platforms.sfo2.cdn.digitaloceanspaces.com/WWW/Badge%201.svg)](https://www.digitalocean.com/?refcode=f4ea6ef24c13&utm_campaign=Referral_Invite&utm_medium=Referral_Program&utm_source=badge)

# 📼 Credits

## Translators

Thanks to our great translators!

If you would like to volunteer and assist in translating, see [this page](https://pwpush.com/en/pages/translate).

| Name   | Language  | |
|---|---|---|
| [Oyale](https://github.com/oyale) | [Catalan](https://pwpush.com/ca) | |
| Finn Skaaning  |  [Danish](https://pwpush.com/da/p/ny) | |
| [Mihail Tchetchelnitski](https://github.com/mtchetch)  | [Finnish](https://pwpush.com/fi/p/uusi)  | |
| [Thibaut](https://github.com/tibo59) | [French](https://pwpush.com/fr/p/Nouveau) | |
| Thomas Wölk | [German](https://pwpush.com/de/p/neu) | [Github](https://github.com/confluencepoint/), [Twitter](https://twitter.com/confluencepoint) |
| Martin Otto |[German](https://pwpush.com/de/p/neu) | |
| Robin Jørgensen |[Norwegian](https://pwpush.com/no/p/ny) | |
| [Łukasz](https://github.com/drpt)|[Polish](https://pwpush.com/pl/p/nowy) | |
| [Jair Henrique](https://github.com/jairhenrique/) | [Portuguese](https://pwpush.com/pt-br/p/novo) | |
| [Fabrício Rodrigues](https://www.linkedin.com/in/ifabriciorodrigues/)| [Portuguese](https://pwpush.com/pt-br/p/novo) | |
| [Ivan Freitas](https://github.com/IvanMFreitas)| [Portuguese](https://pwpush.com/pt-br/p/novo) | |
| Sara Faria| [Portuguese](https://pwpush.com/pt-br/p/novo) | |
| [Oyale](https://github.com/oyale) |[Spanish](https://pwpush.com/pt-br/p/novo) | |
| johan323 |[Swedish](https://pwpush.com/sv/p/ny) | |
| Fredrik Arvas|[Swedish](https://pwpush.com/sv/p/ny) | |
| Pedro Marques | [European Portuguese](https://pwpush.com/pt-pt/p/novo) | |

Also thanks to [translation.io](https://translation.io) for their great service in managing translations.  It's also generously free for opensource projects.

## Containers

Thanks to:

* [@fiskhest](https://github.com/fiskhest) the [Kubernetes installation instructions and manifests](https://github.com/pglombardo/PasswordPusher/tree/master/containers/kubernetes).

* [@sfarosu](https://github.com/sfarosu) for [contributing](https://github.com/pglombardo/PasswordPusher/pull/82) the Docker, Kubernetes & OpenShift container support.

* [sirux88](https://github.com/sirux88) for cleaning up the Docker files and adding multistage builds.

## Other

Thanks to:

* [@iandunn](https://github.com/iandunn) for better password form security.

* [Kasper 'kapöw' Grubbe](https://github.com/kaspergrubbe) for the [JSON POST fix](https://github.com/pglombardo/PasswordPusher/pull/3).

* [JarvisAndPi](http://www.reddit.com/user/JarvisAndPi) for the favicon design

...and many more.  See the [Contributors page](https://github.com/pglombardo/PasswordPusher/graphs/contributors) for more details.

# 🛡 License

[![License](https://img.shields.io/github/license/pglombardo/PasswordPusher)](https://github.com/pglombardo/PasswordPusher/blob/main/LICENSE)

This project is licensed under the terms of the `Apache License 2.0` license. See [LICENSE](https://github.com/pglombardo/PasswordPusher/blob/main/LICENSE) for more details.

# 📃 Citation

```bibtex
@misc{PasswordPusher,
  author = {Peter Giacomo Lombardo},
  title = {An application to securely communicate passwords over the web. Passwords automatically expire after a certain number of views and/or time has passed.},
  year = {2022},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/pglombardo/PasswordPusher}}
}
```
