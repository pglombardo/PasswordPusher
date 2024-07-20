<div align="center">

[![Password Pusher Front Page](https://pwpush.fra1.cdn.digitaloceanspaces.com/branding/logos/horizontal-logo-small.png)](https://pwpush.com/)

__Simple & Secure Password Sharing with Auto-Expiration of Shared Items__

[![](https://badgen.net/twitter/follow/pwpush)](https://twitter.com/pwpush)
![](https://badgen.net/github/stars/pglombardo/PasswordPusher)
[![](https://badgen.net/uptime-robot/month/m789048867-17b5770ccd78208645662f1f)](https://stats.uptimerobot.com/6xJjNtPr93)
[![](https://badgen.net/docker/pulls/pglombardo/pwpush-ephemeral)](https://hub.docker.com/repositories)

[![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/pglombardo/PasswordPusher/ruby-tests.yml)](https://github.com/pglombardo/PasswordPusher/actions/workflows/ruby-tests.yml)
[![Dependencies Status](https://img.shields.io/badge/dependencies-up%20to%20date-brightgreen.svg)](https://github.com/pglombardo/pwpush-cli/pulls?utf8=%E2%9C%93&q=is%3Apr%20author%3Aapp%2Fdependabot)
[![Semantic Versions](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--versions-e10079.svg)](https://github.com/pglombardo/pwpush-cli/releases)
[![License](https://img.shields.io/github/license/pglombardo/PasswordPusher)](https://github.com/pglombardo/PasswordPusher/blob/master/LICENSE)

</div>

------

Give your users the tools to be secure by default.

Password Pusher is an open source application to communicate passwords over the web. Links to passwords expire after a certain number of views and/or time has passed.

Hosted at [pwpush.com](https://pwpush.com) but you can also easily run your own private instance with just a few steps.

* __Easy-to-install:__ Host your own via Docker, a cloud service or just use [pwpush.com](https://pwpush.com)
* __Open Source:__ No blackbox code.  Only trusted, tested and reviewed open source code.
* __Versatile:__ Push passwords, text, files or URLs that auto-expire and self delete.
* __Audit logging:__ Track and control what you've shared and see who has viewed it.
* __Encrypted storage:__ All sensitive data is stored encrypted and deleted entirely once expired.
* __Host your own:__ Database backed or ephemeral, easily run your own instance isolated from the world.
* __JSON API:__ Raw JSON API available for 3rd party tools or command line via `curl` or `wget`.
* __Command line interface:__ Automate your password distribution with CLI tools or custom scripts.
* __Logins__: Invite your colleagues and track what is pushed and who retrieved it.
* __Admin Dashboard:__ Manage your self-hosted instance with a built in admin dashboard.
* __Internationalized:__ 29 language translations are bundled in.  Easily selectable via UI or URL
* __Themes:__ [26 themes](https://docs.pwpush.com/docs/themes/) bundled in courtesy of Bootswatch.  Select with a simple environment variable.
* __Unbranded delivery page:__ No logos, superfluous text or unrelated links to confuse end users.
* __Customizable:__ Change text and default options via environment variables.
* __Light & dark themes:__  Via CSS @media integration, the default site theme follows your local preferences.
* __Re-Brandable:__ Customize the site name, tagline and logo to fit your environment.
* __Custom CSS:__ Bundle in your own custom CSS to add your own design.
* __>10 Years Old:__ Password Pusher has securely delivered millions and millions of passwords in its 10 year history.
* __Actively Maintained:__ I happily work for the good karma of the great IT/Security community.
* __Honest Software:__  Open source written and maintained by [me](https://github.com/pglombardo) with the help of some great contributors.  No organizations, corporations or evil agendas.

💌 --> Sign up for [the newsletter](https://buttondown.email/pwpush?tag=github) to get updates on big releases, security issues, new features, integrations, tips and more.

Password Pusher is also [on Twitter](https://twitter.com/pwpush), [Gettr](https://gettr.com/user/pwpush) and [on Facebook](https://www.facebook.com/pwpush)

-----

[![](./app/assets/images/features/front-page-thumb.png)](./app/assets/images/features/front-page-large.png)
[![](./app/assets/images/features/audit-log-thumb.png)](./app/assets/images/features/audit-log-large.png)
[![](./app/assets/images/features/secret-url-languages-thumb.png)](./app/assets/images/features/secret-url-languages-large.png)
[![](./app/assets/images/features/password-generator-thumb.png)](./app/assets/images/features/password-generator-large.png)
[![](./app/assets/images/features/dark-theme-thumb.png)](./app/assets/images/features/dark-theme.gif)
[![](./app/assets/images/features/preliminary-step-thumb.png)](./app/assets/images/features/preliminary-step.gif)


# ⚡️ Quick Start

→ Go to [pwpush.com](https://pwpush.com) and try it out.

_or_

→ Run your own instance with `docker run -d -p "5100:5100" pglombardo/pwpush:latest` or a [production ready setup with a database & SSL/TLS](https://github.com/pglombardo/PasswordPusher/tree/master/containers/docker/all-in-one).

_or_

→ Use one of the [3rd party tools](#3rd-party-tools) that interface with Password Pusher.

# Documentation

See the full [Password Pusher documentation here](https://docs.pwpush.com).

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

Also thanks to [translation.io](https://translation.io) for their great service in managing translations.  It's also generously free for open source projects.

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

[![License](https://img.shields.io/github/license/pglombardo/PasswordPusher)](https://github.com/pglombardo/PasswordPusher/blob/master/LICENSE)

This project is licensed under the terms of the `Apache License 2.0` license. See [LICENSE](https://github.com/pglombardo/PasswordPusher/blob/master/LICENSE) for more details.

# 📃 Citation

```bibtex
@misc{PasswordPusher,
  author = {Peter Giacomo Lombardo},
  title = {An application to securely communicate passwords over the web. Passwords automatically expire after a certain number of views and/or time has passed.},
  year = {2024},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/pglombardo/PasswordPusher}}
}
```
