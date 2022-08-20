
# Overview

Password Pusher can largely be configured by environment variables.  These can modify behaviour, enable & disable features and change application defaults.

See the following sections for the area you are interested in.

# Application Encryption

Password Pusher encrypts sensitive data in the database. This requires a randomly generated encryption key for each application instance.

To set a custom encryption key for your application, set the environment variable `PWPUSH_MASTER_KEY`:

    PWPUSH_MASTER_KEY=0c110f7f9d93d2122f36debf8a24bf835f33f248681714776b336849b801f693

## Generate a New Encryption Key

Key generation can be done through the [helper tool](https://pwpush.com/pages/generate_key) or on the command line in the application source using `Lockbox.generate_key`:

```ruby
bundle
rails c
Lockbox.generate_key
```

Notes:

* If an encryption key isn't provided, a default key will be used.
* The best security for private instances of Password Pusher is to use your own custom encryption key although it is not required.
* The risk in using the default key is lessened if you keep your instance secure and your push expirations short. e.g. 1 day/1 view versus 100 days/100 views.
* Once a push expires, all encrypted data is deleted.
* Changing an encryption key where old pushes already exist will make those older pushes unreadable. In other words, the payloads will be garbled. New pushes going forward will work fine.


# Changing Application Defaults

| Environment Variable | Description | Default Value |
| --------- | ------------------ | --- |
| EXPIRE_AFTER_DAYS_DEFAULT | Controls the "Expire After Days" default value in Password#new | `7` |
| EXPIRE_AFTER_DAYS_MIN | Controls the "Expire After Days" minimum value in Password#new | `1` |
| EXPIRE_AFTER_DAYS_MAX | Controls the "Expire After Days" maximum value in Password#new | `90` |
| EXPIRE_AFTER_VIEWS_DEFAULT | Controls the "Expire After Views" default value in Password#new | `5` |
| EXPIRE_AFTER_VIEWS_MIN | Controls the "Expire After Views" minimum value in Password#new | `1` |
| EXPIRE_AFTER_VIEWS_MAX | Controls the "Expire After Views" maximum value in Password#new | `100` |
| DELETABLE_PASSWORDS_ENABLED | Can passwords be deleted by viewers? When true, passwords will have a link to optionally delete the password being viewed | `false` |
| DELETABLE_PASSWORDS_DEFAULT | When the above is `true`, this sets the default value for the option. | `true` |
| RETRIEVAL_STEP_ENABLED | When `true`, adds an option to have a preliminary step to retrieve passwords.  | `true` |
| RETRIEVAL_STEP_DEFAULT | Sets the default value for the retrieval step for newly created passwords. | `false` |
| PWP__DEFAULT_LOCALE | Sets the default language for the application.  See the [documentation](https://github.com/pglombardo/PasswordPusher#internationalization). | `en` |

# Enabling Logins

To enable logins in your instance of Password Pusher, you must have an SMTP server available to send emails through.  These emails are sent for events such as password reset, unlock, registration etc..

To use logins, you should be running a databased backed version of Password Pusher.  Logins will likely work in ephemeral but aren't suggested since all data is wiped with every restart.

_All_ of the following environments need to be set (except SMTP authentication if none) for application logins to function properly.

| Environment Variable | Description | Value |
| --------- | ------------------ | --- |
| PWP__ENABLE_LOGINS | On/Off switch for logins. | `true` |
| PWP__ALLOW_ANONYMOUS | When false, requires a login for the front page (to push new passwords). | `true` |
| PWP__MAIL__RAISE_DELIVERY_ERRORS | Email delivery errors will be shown in the application | `true` |
| PWP__MAIL__SMTP_ADDRESS | Allows you to use a remote mail server. Just change it from its default "localhost" setting. | `smtp.domain.com` |
| PWP__MAIL__SMTP_PORT | Port of the SMTP server | `587` |
| PWP__MAIL__SMTP_USER_NAME | If your mail server requires authentication, set the username in this setting. | `smtp_username` |
| PWP__MAIL__SMTP_PASSWORD | If your mail server requires authentication, set the password in this setting. | `smtp_password` |
| PWP__MAIL__SMTP_AUTHENTICATION | If your mail server requires authentication, you need to specify the authentication type here. This is a string and one of :plain (will send the password in the clear), :login (will send password Base64 encoded) or :cram_md5 (combines a Challenge/Response mechanism to exchange information and a cryptographic Message Digest 5 algorithm to hash important information) | `plain` |
| PWP__MAIL__SMTP_STARTTLS | Use STARTTLS when connecting to your SMTP server and fail if unsupported. | `true` |
| PWP__MAIL__OPEN_TIMEOUT | Number of seconds to wait while attempting to open a connection. | `10` |
| PWP__MAIL__READ_TIMEOUT | Number of seconds to wait until timing-out a read(2) call. | `10` |
| PWP__HOST_DOMAIN | Used to build fully qualified URLs in emails.  Where is your instance hosted? | `pwpush.com` |
| PWP__HOST_PROTOCOL | The protocol to access your Password Pusher instance.  HTTPS advised. | `https` |
| PWP__MAIL__MAILER_SENDER | This is the "From" address in sent emails. | '"Company Name" <user@example.com>' |

## Shell Example

```
export PWP__ENABLE_LOGINS=true
export PWP__MAIL__RAISE_DELIVERY_ERRORS=true
export PWP__MAIL__SMTP_ADDRESS=smtp.mycompany.org
export PWP__MAIL__SMTP_PORT=587
export PWP__MAIL__SMTP_USER_NAME=yolo
export PWP__MAIL__SMTP_PASSWORD=secret
export PWP__MAIL__SMTP_AUTHENTICATION=plain
export PWP__MAIL__SMTP_STARTTLS=true
export PWP__MAIL__OPEN_TIMEOUT=10
export PWP__MAIL__READ_TIMEOUT=10
export PWP__HOST_DOMAIN=pwpush.mycompany.org
export PWP__HOST_PROTOCOL=https
export PWP__MAIL__MAILER_SENDER='"Spiderman" <thespider@mycompany.org>'
```

* See also this [Github discussion](https://github.com/pglombardo/PasswordPusher/issues/265#issuecomment-964432942).
* [External Documentation on mailer configuration](https://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration) for the underlying technology if you need more details for configuration issues.

# Rebranding

Password Pusher has the ability to be [re-branded](https://twitter.com/pwpush/status/1557658305325109253) with your own site title, tagline and logo.

This can be done with the following environment variables:

| Environment Variable | Description | Default Value |
| --------- | ------------------ | --- |
| PWP__BRAND__TITLE | Title for the site. | `Password Pusher` |
| PWP__BRAND__TAGLINE | Tagline for the site.  | `Go Ahead.  Email Another Password.` |
| PWP__BRAND__SHOW_FOOTER_MENU | On/Off switch for the footer menu. | `true` |
| PWP__BRAND__LIGHT_LOGO | Site logo image for the light theme. | `media/img/logo-transparent-sm-bare.png` |
| PWP__BRAND__DARK_LOGO | Site logo image for the dark theme. | `media/img/logo-transparent-sm-bare.png` |

See the `brand` section of [settings.yml](https://github.com/pglombardo/PasswordPusher/blob/master/config/settings.yml) for more details, examples and description.


# Google Analytics

| Environment Variable | Description |
| --------- | ------------------ |
| GA_ENABLE | The existence of this variable will enable the Google Analytics for the application.  See `app/views/layouts/_ga.html.erb`.|
| GA_ACCOUNT | The Google Analytics account id.  E.g. `UA-XXXXXXXX-X` |
| GA_DOMAIN | The domain where the application is hosted.  E.g. `pwpush.com` |

# Forcing SSL Links

See also the Proxies section below.

| Environment Variable | Description |
| --------- | ------------------ |
| FORCE_SSL | The existence of this variable will set `config.force_ssl` to `true` and generate HTTPS based secret URLs

# Proxies

An occasional issue is that when using Password Pusher behind a proxy, the generated secret URLs are incorrect.  They often have the backend URL & port instead of the public fully qualified URL - or use HTTP instead of HTTPS (or all of the preceding).

To resolve this, make sure your proxy properly forwards the `X-Forwarded-Host`, `X-Forwarded-Port` and `X-Forwarded-Proto` headers.

The values in these headers represent the front end request.  When these headers are sent, Password Pusher can then build the correct URLs.

If you are unable to have these headers passed to the application for any reason, you could instead force an override of the base URL using the `PWP__OVERRIDE_BASE_URL` environment variable.

| Environment Variable | Description | Example Value |
| --------- | ------------------ | --- |
| PWP__OVERRIDE_BASE_URL | Set this value (without a trailing slash) to force the base URL of generated links. | 'https://subdomain.domain.dev'
