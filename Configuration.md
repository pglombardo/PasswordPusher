
# Overview

Configure everything from defaults, features, branding, languages and more.

# How to Configure the Application

Password Pusher uses a centralized configuration that is stored in [config/settings.yml](https://github.com/pglombardo/PasswordPusher/blob/master/config/settings.yml).  This file contains all of the settings that is configurable for the application.

There are two ways to modify the settings in this file:

1. Use environment variable that override this file
2. Modify the file itself

For a few modifications, environment variables are the easy route.  For more extensive configuration, it's suggested to maintain your own custom `settings.yml` file across updates.

Read on for details on both methods.

## Configuring via Environment variables

The settings in the `config/settings.yml` file can be overridden by environment variables.  A listing and description of these environment variables is available in this documentation below and also in the [settings.yml](https://github.com/pglombardo/PasswordPusher/blob/master/config/settings.yml) file itself.

### Shell Example

```sh
# Change the default language for the application to French
export PWP__DEFAULT_LOCALE='fr'
```
### Docker Example

```sh
# Change the default language for the application to French
docker run -d --env PWP__DEFAULT_LOCALE=fr -p "5100:5100" pglombardo/pwpush-ephemeral:release
```

_Tip: If you have to set a large number of environment variables for Docker, consider using a Docker env-file.  There is an [example docker-env-file](https://github.com/pglombardo/PasswordPusher/blob/master/containers/docker/pwpush-docker-env-file) with instructions available._

## Configuring via a Custom `settings.yml` File

If you prefer, you can take the [default settings.yml file](https://github.com/pglombardo/PasswordPusher/blob/master/config/settings.yml), modify it and apply it to the Password Pusher Docker container.

Inside the Password Pusher Docker container:
* application code exists in the path `/opt/PasswordPusher/`
* the `settings.yml` file is located at `/opt/PasswordPusher/config/settings.yml`

To replace this file with your own custom version, you can launch the Docker container with a bind mount option:

```sh
    docker run -d \
      --mount type=bind,source=/path/settings.yml,target=/opt/PasswordPusher/config/settings.yml \
      -p "5100:5100" pglombardo/pwpush-ephemeral:release
```

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

## Application General

| Environment Variable | Description | Default Value |
| --------- | ------------------ | --- |
| PWP__DEFAULT_LOCALE | Sets the default language for the application.  See the [documentation](https://github.com/pglombardo/PasswordPusher#internationalization). | `en` |
| PWP__RELATIVE_ROOT | Runs the application in a subfolder.  e.g. With a value of `pwp` the front page will then be at `https://url/pwp` | `Not set` |

## Password Push Expiration Settings

| Environment Variable | Description | Default Value |
| --------- | ------------------ | --- |
| PWP__PW__EXPIRE_AFTER_DAYS_DEFAULT | Controls the "Expire After Days" default value in Password#new | `7` |
| PWP__PW__EXPIRE_AFTER_DAYS_MIN | Controls the "Expire After Days" minimum value in Password#new | `1` |
| PWP__PW__EXPIRE_AFTER_DAYS_MAX | Controls the "Expire After Days" maximum value in Password#new | `90` |
| PWP__PW__EXPIRE_AFTER_VIEWS_DEFAULT | Controls the "Expire After Views" default value in Password#new | `5` |
| PWP__PW__EXPIRE_AFTER_VIEWS_MIN | Controls the "Expire After Views" minimum value in Password#new | `1` |
| PWP__PW__EXPIRE_AFTER_VIEWS_MAX | Controls the "Expire After Views" maximum value in Password#new | `100` |
| PWP__PW__ENABLE_DELETABLE_PUSHES | Can passwords be deleted by viewers? When true, passwords will have a link to optionally delete the password being viewed | `false` |
| PWP__PW__DELETABLE_PUSHES_DEFAULT | When the above is `true`, this sets the default value for the option. | `true` |
| PWP__PW__ENABLE_RETRIEVAL_STEP | When `true`, adds an option to have a preliminary step to retrieve passwords.  | `true` |
| PWP__PW__RETRIEVAL_STEP_DEFAULT | Sets the default value for the retrieval step for newly created passwords. | `false` |
| PWP__PW__ENABLE_BLUR | Enables or disables the 'blur' effect when showing a push payload to the user. | `true` |


## Password Generator Settings

| Environment Variable | Description | Default Value |
| --------- | ------------------ | --- |
| PWP__GEN__HAS_NUMBERS | Controls whether generated passwords have numbers | `true` |
| PWP__GEN__TITLE_CASED | Controls whether generated passwords will be title cased | `true` |
| PWP__GEN__USE_SEPARATORS | Controls whether generated passwords will use separators between syllables | `true` |
| PWP__GEN__CONSONANTS | The list of consonants to generate from | `bcdfghklmnprstvz` |
| PWP__GEN__VOWELS | The list of vowels to generate from | `aeiouy` |
| PWP__GEN__SEPARATORS | If `use_separators` is enabled above, the list of separators to use (randomly) | `-_=` |
| PWP__GEN__MAX_SYLLABLE_LENGTH | The maximum length of each syllable that a generated password can have | `3` |
| PWP__GEN__MIN_SYLLABLE_LENGTH | The minimum length of each syllable that a generated password can have | `1` |
| PWP__GEN__SYLLABLES_COUNT | The exact number of syllables that a generated password will have | `3` |

# Enabling Logins

To enable logins in your instance of Password Pusher, you must have an SMTP server available to send emails through.  These emails are sent for events such as password reset, unlock, registration etc..

To use logins, you should be running a databased backed version of Password Pusher.  Logins will likely work in ephemeral but aren't suggested since all data is wiped with every restart.

_All_ of the following environments need to be set (except SMTP authentication if none) for application logins to function properly.

| Environment Variable | Description | Default |
| --------- | ------------------ | --- |
| PWP__ENABLE_LOGINS | On/Off switch for logins. | `false` |
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
| PWP__DISABLE_SIGNUPS| Once your user accounts are created, you can set this to disable any further user account creation.  Sign up links and related backend functionality is disabled when `true`. | `false` |
| PWP__SIGNUP_EMAIL_REGEXP | The regular expression used to validate emails for new user signups.  This can be modified to limit new account creation to a subset of domains. e.g. <code>\A[^@\s]+@(hey\.com\|gmail\.com)\z</code>.  _Tip: use https://rubular.com to test out your regular expressions. It includes a guide to what each component means in regexp._ | `\A[^@\s]+@[^@\s]+\z` |

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

# Enabling File Pushes

To enable file uploads (File Pushes) in your instance of Password Pusher, there are a few requirements:

1.  you must have logins enabled (see above)
2.  specify a place to store uploaded files
3.  If you use cloud storage, configure the CORS configuration in your buckets (detailed below)

The following settings enable/disable the feature and specify where to store uploaded files.

This feature can store uploads on local disk (not valid for Docker containers), Amazon S3, Google Cloud Storage or Azure Storage.

## General Settings

| Environment Variable | Description | Value(s) |
| --------- | ------------------ | --- |
| PWP__ENABLE_FILE_PUSHES | On/Off switch for File Pushes. | `false` |
| PWP__FILES__STORAGE | Chooses the storage area for uploaded files. | `local`, `amazon`, `google` or `microsoft` |
| PWP__FILES__ENABLE_BLUR | Enables or disables the 'blur' effect when showing a text payload to the user. | `true` |

## File Push Expiration Settings

| Environment Variable | Description | Default Value |
| --------- | ------------------ | --- |
| PWP__FILES__EXPIRE_AFTER_DAYS_DEFAULT | Controls the "Expire After Days" default value in Password#new | `7` |
| PWP__FILES__EXPIRE_AFTER_DAYS_MIN | Controls the "Expire After Days" minimum value in Password#new | `1` |
| PWP__FILES__EXPIRE_AFTER_DAYS_MAX | Controls the "Expire After Days" maximum value in Password#new | `90` |
| PWP__FILES__EXPIRE_AFTER_VIEWS_DEFAULT | Controls the "Expire After Views" default value in Password#new | `5` |
| PWP__FILES__EXPIRE_AFTER_VIEWS_MIN | Controls the "Expire After Views" minimum value in Password#new | `1` |
| PWP__FILES__EXPIRE_AFTER_VIEWS_MAX | Controls the "Expire After Views" maximum value in Password#new | `100` |
| PWP__FILES__ENABLE_DELETABLE_PUSHES | Can passwords be deleted by viewers? When true, passwords will have a link to optionally delete the password being viewed | `false` |
| PWP__FILES__DELETABLE_PUSHES_DEFAULT | When the above is `true`, this sets the default value for the option. | `true` |
| PWP__FILES__ENABLE_RETRIEVAL_STEP | When `true`, adds an option to have a preliminary step to retrieve passwords.  | `true` |
| PWP__FILES__RETRIEVAL_STEP_DEFAULT | Sets the default value for the retrieval step for newly created passwords. | `false` |

## Local Storage

`PWP__FILES__STORAGE=local`

The default location for local storage is `./storage`.

If using containers and you prefer local storage, you can add a volume mount to the container at the path `/opt/PasswordPusher/storage`:

`docker run -d -p "5100:5100" -v /var/lib/pwpush/files:/opt/PasswordPusher/storage pglombardo/pwpush-postgres:release`

Please _make sure_ that the directory is writeable by the docker container.

A CORS configuration is not required for local storage.

## Amazon S3

To configure the application to store files in an Amazon S3 bucket, you have to:

1. set the required environment variables detailed below (or the equivalent values in `settings.yml`)
2. apply a CORS configuration to your S3 bucket (see next section)

| Environment Variable | Description | Value(s) |
| --------- | ------------------ | --- |
| PWP__FILES__STORAGE | Storage Provider Selection | `amazon` |
| PWP__FILES__S3__ENDPOINT | S3 Endpoint | None |
| PWP__FILES__S3__ACCESS_KEY_ID | Access Key ID | None |
| PWP__FILES__S3__SECRET_ACCESS_KEY | Secret Access Key| None |
| PWP__FILES__S3__REGION | S3 Region| None |
| PWP__FILES__S3__BUCKET | The S3 bucket name | None |

### Amazon S3 CORS Configuration

The application performs direct uploads from the browser to your Amazon S3 bucket.  This provides better performance and reduces load on the application itself.

For this to work, you have to add a CORS configuration to your bucket.

This direct upload functionality is done using a library called ActiveStorage.  For the full documentation on configuring CORS for ActiveStorage, [see here](https://edgeguides.rubyonrails.org/active_storage_overview.html#cross-origin-resource-sharing-cors-configuration).

```json
[
  {
    "AllowedHeaders": [
      "Content-Type",
      "Content-MD5",
      "Content-Disposition"
    ],
    "AllowedMethods": [
      "PUT"
    ],
    "AllowedOrigins": [
      "https://www.example.com"  << Change to your URL
    ],
    "MaxAgeSeconds": 3600
  }
]
```
## Google Cloud Storage

To configure the application to store files in Google Cloud Storage, you have to:

1. set the required environment variables detailed below (or the equivalent values in `settings.yml`)
2. apply a CORS configuration (see next section)

| Environment Variable | Description | Value(s) |
| --------- | ------------------ | --- |
| PWP__FILES__STORAGE | Storage Provider Selection | `google` |
| PWP__FILES__GCS__PROJECT | GCS Project | None |
| PWP__FILES__GCS__CREDENTIALS | GCS Credentials | None |
| PWP__FILES__GCS__BUCKET | The GCS bucket name | None |

### Google Cloud Storage CORS Configuration

The application performs direct uploads from the browser to Google Cloud Storage.  This provides better performance and reduces load on the application itself.

For this to work, you have to add a CORS configuration.

This direct upload functionality is done using a library called ActiveStorage.  For the full documentation on configuring CORS for ActiveStorage, [see here](https://edgeguides.rubyonrails.org/active_storage_overview.html#cross-origin-resource-sharing-cors-configuration).

```json
[
  {
    "origin": ["https://www.example.com"],
    "method": ["PUT"],
    "responseHeader": ["Content-Type", "Content-MD5", "Content-Disposition"],
    "maxAgeSeconds": 3600
  }
]
```


## Azure Storage

To configure the application to store files in Azure Storage, you have to:

1. set the required environment variables detailed below (or the equivalent values in `settings.yml`)
2. apply a CORS configuration (see next section)

| Environment Variable | Description | Value(s) |
| --------- | ------------------ | --- |
| PWP__FILES__STORAGE | Storage Provider Selection | `microsoft` |
| PWP__FILES__AS__STORAGE_ACCOUNT_NAME | Azure Storage Account Name | None |
| PWP__FILES__AS__STORAGE_ACCESS_KEY | Azure Storage Account Key | None |
| PWP__FILES__AS__CONTAINER | Azure Storage Container Name | None |

### Azure Storage CORS Configuration

The application performs direct uploads from the browser to Azure Storage.  This provides better performance and reduces load on the application itself.

For this to work, you have to add a CORS configuration.

This direct upload functionality is done using a library called ActiveStorage.  For the full documentation on configuring CORS for ActiveStorage, [see here](https://edgeguides.rubyonrails.org/active_storage_overview.html#cross-origin-resource-sharing-cors-configuration).

```xml
<Cors>
  <CorsRule>
    <AllowedOrigins>https://www.example.com</AllowedOrigins>
    <AllowedMethods>PUT</AllowedMethods>
    <AllowedHeaders>Content-Type, Content-MD5, x-ms-blob-content-disposition, x-ms-blob-type</AllowedHeaders>
    <MaxAgeInSeconds>3600</MaxAgeInSeconds>
  </CorsRule>
</Cors>
```

# Enabling URL Pushes

Similar to file pushes, URL pushes also require logins to be enabled.

| Environment Variable | Description | Default |
| --------- | ------------------ | --- |
| PWP__ENABLE_URL_PUSHES | On/Off switch for URL Pushes. | `false` |

## URL Push Expiration Settings

| Environment Variable | Description | Default Value |
| --------- | ------------------ | --- |
| PWP__URL__EXPIRE_AFTER_DAYS_DEFAULT | Controls the "Expire After Days" default value in Password#new | `7` |
| PWP__URL__EXPIRE_AFTER_DAYS_MIN | Controls the "Expire After Days" minimum value in Password#new | `1` |
| PWP__URL__EXPIRE_AFTER_DAYS_MAX | Controls the "Expire After Days" maximum value in Password#new | `90` |
| PWP__URL__EXPIRE_AFTER_VIEWS_DEFAULT | Controls the "Expire After Views" default value in Password#new | `5` |
| PWP__URL__EXPIRE_AFTER_VIEWS_MIN | Controls the "Expire After Views" minimum value in Password#new | `1` |
| PWP__URL__EXPIRE_AFTER_VIEWS_MAX | Controls the "Expire After Views" maximum value in Password#new | `100` |
| PWP__URL__ENABLE_DELETABLE_PUSHES | Can passwords be deleted by viewers? When true, passwords will have a link to optionally delete the password being viewed | `false` |
| PWP__URL__DELETABLE_PUSHES_DEFAULT | When the above is `true`, this sets the default value for the option. | `true` |
| PWP__URL__ENABLE_RETRIEVAL_STEP | When `true`, adds an option to have a preliminary step to retrieve passwords.  | `true` |
| PWP__URL__RETRIEVAL_STEP_DEFAULT | Sets the default value for the retrieval step for newly created passwords. | `false` |

# Rebranding

Password Pusher has the ability to be [re-branded](https://twitter.com/pwpush/status/1557658305325109253) with your own site title, tagline and logo.

![](https://pwpush.fra1.cdn.digitaloceanspaces.com/branding%2Fpwpush-brand-example.png)

This can be done with the following environment variables:

| Environment Variable | Description | Default Value |
| --------- | ------------------ | --- |
| PWP__BRAND__TITLE | Title for the site. | `Password Pusher` |
| PWP__BRAND__TAGLINE | Tagline for the site.  | `Go Ahead.  Email Another Password.` |
| PWP__BRAND__SHOW_FOOTER_MENU | On/Off switch for the footer menu. | `true` |
| PWP__BRAND__LIGHT_LOGO | Site logo image for the light theme. | `logo-transparent-sm-bare.png` |
| PWP__BRAND__DARK_LOGO | Site logo image for the dark theme. | `logo-transparent-sm-bare.png` |

The values for the `*_LOGO` images can either be:

1. Fully qualified HTTP(s) URLS such as `https://pwpush.fra1.cdn.digitaloceanspaces.com/dev%2Facme-logo.jpg` (easiest)
2. Relative path that is mounted inside the container

As an example for #2 above, say you place your logo images locally into `/var/lib/pwpush/logos/`.  You would then mount that directory into the container:

`docker run -d -p "5100:5100" -v /var/lib/pwpush/logos:/opt/PasswordPusher/public/logos pglombardo/pwpush-postgres:release`

or alternatively for a `docker-compose.yml` file:

```yaml
volumes:
  # Example of a persistent volume for the storage directory (file uploads)
  - /var/lib/pwpush/logos:/opt/PasswordPusher/public/logos:r
```

See [here](https://github.com/pglombardo/PasswordPusher/blob/master/containers/docker/pwpush-postgres/docker-compose.yml) for a larger Docker Compose explanation.

With this setup, you can then set your `LOGO` environment variables (or `settings.yml` options) to:

```
PWP__BRAND__LIGHT_LOGO=/logos/mylogo.png
```

## See Also

* the `brand` section of [settings.yml](https://github.com/pglombardo/PasswordPusher/blob/master/config/settings.yml) for more details, examples and description.
* [this issue comment](https://github.com/pglombardo/PasswordPusher/issues/432#issuecomment-1282158006) on how to mount images into the contianer and set your environment variables accordingly

# Change the Default Lanugage

The application comes with more than 24 languages bundled in which are selectable inside the application.  The default language of the application is English.  If you would like to change this default language, simply set the following environment variable for your application.

```PWP__DEFAULT_LOCALE=is```

A list of supported languages (and their language codes) can be found in the [settings.yml](https://github.com/pglombardo/PasswordPusher/blob/master/config/settings.yml#L702-L734) file under `language_codes`.

Choose which language you would like to have as the default language, and use the two letter code as the value for the environment variable.

# Themes

![](https://pwpush.fra1.cdn.digitaloceanspaces.com/themes%2Fquartz-theme-pwpush.com.png)

Password Pusher supports **26 themes out of the box**.  These themes are taken directly from the great [Bootswatch](https://bootswatch.com) project and are unmodified.

As such, themes mostly work although there may be a rare edge cases where fonts may not be clear or something doesn't display correctly.  If this is the case you can add custom CSS styles to fix any such issues.  See the next section on how to add custom styling.

---> Checkout the [Themes Gallery](Themes.md)!

The Bootswatch themes are licensed under the MIT license.

## Configuring a Theme

To specify a theme for your Password Pusher instance, you must set __two__ environment variables:the `PWP__THEME` environment variable to specify the theme and `PWP__PRECOMPILE=true` environment variable to have CSS assets recompiled on container boot.

**Make sure to set both `PWP__THEME` and `PWP__PRECOMPILE` for the selected theme to work.** 👍

| Environment Variable | Description | Possible Values |
| --------- | ------------------ | --- |
| PWP__THEME | Theme used for the application. |    'cerulean', 'cosmo', 'cyborg', 'darkly', 'flatly', 'journal', 'litera', 'lumen', 'lux', 'materia', 'minty', 'morph', 'pulse', 'quartz', 'sandstone', 'simplex', 'sketchy', 'slate', 'solar', 'spacelab', 'superhero', 'united', 'vapor', 'yeti', 'zephyr' |
| PWP__PRECOMPILE | Forces a rebuild of the theme CSS on boot. | `true` |

---> See the [Themes Gallery](Themes.md) for examples of each.

__Note:__ Since the theme is a boot level selection, the theme can only be selected by setting the `PWP__THEME` environment variable (and not modifying `settings.yml`).

So to set the `quartz` theme for a Docker container:

```bash
docker run --env PWP__THEME=quartz --env PWP__PRECOMPILE=true -p "5100:5100" pglombardo/pwpush-ephemeral:1.26.10
```

or alternatively for source code:

```bash
export PWP__THEME=quartz
bin/rails asset:precompile # manually recompile assets
bin/rails server
```

## How to Precompile CSS Assets

Password Pusher has a pre-compilation step of assets.  This is used to fingerprint assets and pre-process CSS code for better performance.

If using Docker containers, you can simply set the `PWP__PRECOMPILE=true` environment variable.  On container boot, all assets will be precompiled and bundled into `/assets`.

To manually precompile assets run `bin/rails assets:precompile`.

## Adding an entirely new theme from scratch

The `PWP__THEME` environment variable simply causes the application to load a css file from `app/assets/stylesheets/themes/{$PWP__THEME}.css`.  If you were to place a completely custom CSS file into that directory, you could then set the `PWP__THEME` environment variable to the filename that you added.

For example:

Add `app/assets/stylesheets/themes/mynewtheme.css` and set `PWP__THEME=mynewtheme`.

This would cause that CSS file to be loaded and used as the theme for the site.  Please refer to existing themes if you would like to author your theme for Password Pusher.

Remember that after the new theme is configured, assets must be precompiled again.  See the the previous section for instructions

# How to Add Custom CSS

Password Pusher supports adding custom CSS to the application.  The application hosts a `custom.css` file located at `app/assets/stylesheets/custom.css`.  This file is loaded last so it take precedence over all built in themes and styling.

This file can either be modified directly or in the case of Docker containers, a new file mounted over the existing one.

When changing this file inside a Docker container, make sure to set the precompile option `PWP__PRECOMPILE=true`.  This will assure that the custom CSS is incorporated correctly.

An example Docker command to override that file would be:

```
docker run -e PWP__PRECOMPILE=true --mount type=bind,source=/path/to/my/custom.css,target=/opt/PasswordPusher/app/assets/stylesheets/custom.css -p 5100:5100 pglombardo/pwpush-ephemeral:release
```
or the `docker-compose.yml` equivalent:

```
version: '2.1'
services:

  pwpush:
    image: docker.io/pglombardo/pwpush-ephemeral:release
    ports:
      - "5100:5100"
    environment:
      PWP__PRECOMPILE: 'true'
    volumes:
      - type: bind
        source: /path/to/my/custom.css
        target: /opt/PasswordPusher/app/assets/stylesheets/custom.css
```

Remember that when doing this, this new CSS code has to be precompiled.

To do this in Docker containers, simply set the environment variable `PWP__PRECOMPILE=true`.  For source code, run `bin/rails assets:precompile`.  This compilation process will incorporate the custom CSS into the updated site theme. 

# Google Analytics

| Environment Variable | Description |
| --------- | ------------------ |
| GA_ENABLE | The existence of this variable will enable the Google Analytics for the application.  See `app/views/layouts/_ga.html.erb`.|
| GA_ACCOUNT | The Google Analytics account id.  E.g. `UA-XXXXXXXX-X` |
| GA_DOMAIN | The domain where the application is hosted.  E.g. `pwpush.com` |

# Throttling

Throttling enforces a minimum time interval
between subsequent HTTP requests from a particular client, as
well as by defining a maximum number of allowed HTTP requests
per a given time period (per second, minute, hourly, or daily).

| Environment Variable | Description | Default Value |
| --------- | ------------------ | --- |
| PWP__THROTTLING__DAILY | The maximum number of allowed HTTP requests per day | `1000` |
| PWP__THROTTLING__HOURLY | The maximum number of allowed HTTP requests per hour | `100` |
| PWP__THROTTLING__MINUTE | The maximum number of allowed HTTP requests per minute | `30` |
| PWP__THROTTLING__SECOND | The maximum number of allowed HTTP requests per second | `2` |


# Logging

| Environment Variable | Description |
| --------- | ------------------ |
| PWP__LOG_LEVEL | Set the logging level for the application.  Valid values are: `debug`, `info`, `warn`, `error` and `fatal`.  Note: lowercase.
| PWP__LOG_TO_STDOUT | Set to 'true' to have log output sent to STDOUT instead of log files.  Default: `false`


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
