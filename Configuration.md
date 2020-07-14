
# Environment Variables

For all deployment strategies, the application and it's defaults can be controlled with the following environment variables.

See also `config/environment.rb`.

## Application Encryption

These variables set the encryption key and salt used with EZCrypto library to write passwords to the database.  If not set, the application will use default values.

| Variable | Description |
| --------- | ------------------ |
| CRYPT_KEY | Set the encryption key for the application |
| CRYPT_SALT | And the salt |

To generate a new key and salt, you can use any sufficiently random string or generate one with the application:

```ruby
bundle exec rails console
key = EzCrypto::Key.generate
key.encode
```

You can read more about [EzCrypto here](https://github.com/pglombardo/ezcrypto).

## Application Defaults

| Variable | Description | Default Value |
| --------- | ------------------ | --- |
| PAYLOAD_INITIAL_TEXT | Overrides the default password input value. | `Enter the Password to be Shared` |
| EXPIRE_AFTER_DAYS_DEFAULT | Controls the "Expire After Days" default value in Password#new | 7 |
| EXPIRE_AFTER_DAYS_MIN | Controls the "Expire After Days" minimum value in Password#new | 1 |
| EXPIRE_AFTER_DAYS_MAX | Controls the "Expire After Days" maximum value in Password#new | 90 |
| EXPIRE_AFTER_VIEWS_DEFAULT | Controls the "Expire After Views" default value in Password#new | 5 |
| EXPIRE_AFTER_VIEWS_MIN | Controls the "Expire After Views" minimum value in Password#new | 1 |
| EXPIRE_AFTER_VIEWS_MAX | Controls the "Expire After Views" maximum value in Password#new | 100 |
| DELETABLE_BY_VIEWER_PASSWORDS | Can passwords be deleted by viewers? When true, passwords will have a link to optionally delete the password being viewed | False |
| DELETABLE_BY_VIEWER_DEFAULT | When the above is true, this sets the default value for the option. |

## SSL

| Variable | Description |
| --------- | ------------------ |
| FORCE_SSL | The existence of this variable will set `config.force_ssl` to true

## Google Analytics

| Variable | Description |
| --------- | ------------------ |
| GA_ENABLE | The existence of this variable will enable the Google Analytics for the application.  See `app/views/layouts/_ga.html.erb`.|
| GA_ACCOUNT | The Google Analytics account id.  E.g. `UA-XXXXXXXX-X` |
| GA_DOMAIN | The domain where the application is hosted.  E.g. `pwpush.com` |
