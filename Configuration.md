
# Environment Variables

For all deployment strategies, the application and it's defaults can be controlled with the following environment variables.

See also `config/environment.rb`.

## Application Encryption

Password Pusher encrypts sensitive data in the database. This requires a randomly generated encryption key for each application instance.

To set a custom encryption key for your application, set the environment variable `PWPUSH_MASTER_KEY`:

    PWPUSH_MASTER_KEY=0c110f7f9d93d2122f36debf8a24bf835f33f248681714776b336849b801f693

### Generate a New Encryption Key

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


## Application Defaults

| Variable | Description | Default Value |
| --------- | ------------------ | --- |
| PAYLOAD_INITIAL_TEXT | Overrides the default password input value. | `Enter the Password to be Shared` |
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

## SSL

| Variable | Description |
| --------- | ------------------ |
| FORCE_SSL | The existence of this variable will set `config.force_ssl` to `true` and generate HTTPS based secret URLs

## Google Analytics

| Variable | Description |
| --------- | ------------------ |
| GA_ENABLE | The existence of this variable will enable the Google Analytics for the application.  See `app/views/layouts/_ga.html.erb`.|
| GA_ACCOUNT | The Google Analytics account id.  E.g. `UA-XXXXXXXX-X` |
| GA_DOMAIN | The domain where the application is hosted.  E.g. `pwpush.com` |
