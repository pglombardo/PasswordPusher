![Password Pusher Front Page](https://s3-eu-west-1.amazonaws.com/pwpush/pwpush_logo_2014.png)

This is a heavily modified fork of the [PasswordPusher](https://github.com/pglombardo/PasswordPusher) project.
It is no longer compatible with the official documentation of the API, but supports new features like E2E-encryption.

# API

PasswordPusher allows creating passwords using the API endpoint.
Please consider that passwords which have been created using the API will not benefit from the JavaScript E2E-encryption.

The following POST data is required for Content-Type: `application/x-www-form-urlencoded`:
```
password[payload]: mypassword
password[expire_after_time]: 6
password[expire_after_views]: 2
```

### Properties

#### password[payload]
This will be your password.

#### password[expire_after_time]
Defines the amount of time after which the password will expire.
The following values are allowed:


| `expire_after_time` value  | Time span |
| ------------- | ------------- |
| 1  | 1 hour  |
| 6  | 6 hours  |
| 12  | 12 hours  |
| 24  | 1 day  |
| 48  | 2 days  |
| 72  | 3 days  |
| 96  | 4 days  |
| 120  | 5 days  |

#### password[expire_after_views]
Defines the amount of views after which the password will expire.
The value is allowed to be between `1` and `100`.

### Request examples

An example `curl` request might look like this:
```
curl -X POST --data "password[payload]=mypassword&password[expire_after_time]=1&password[expire_after_views]=10" https://passwordpusher.example/p.json
```

The request produces the following result:
```
{
   "expire_after_time" : 1,
   "updated_at" : "2020-05-26T13:06:02.688Z",
   "payload" : "mypassword",
   "user_id" : null,
   "deletable_by_viewer" : false,
   "deleted" : false,
   "created_at" : "2020-05-26T13:06:02.688Z",
   "expired" : false,
   "id" : 5322,
   "first_view" : true,
   "host" : "passwordpusher.example",
   "url_token" : "dsleq6htuicxnlbr#noClientEncryption",
   "expire_after_views" : 10
}
```
