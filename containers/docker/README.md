See the Docker documentation in the [Password Pusher documentation portal](https://docs.pwpush.com/docs/installation/#docker).

Persistent data belongs on `/opt/PasswordPusher/storage` (SQLite at `storage/db/production.sqlite3`). Do not mount a volume over `/opt/PasswordPusher/db` — that path includes `db/migrate/` and overlaying it breaks upgrades. See [DATABASE_URL](https://docs.pwpush.com/docs/database_url/).
