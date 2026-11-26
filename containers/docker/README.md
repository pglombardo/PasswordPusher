See the Docker documentation in the [Password Pusher documentation portal](https://docs.pwpush.com/docs/installation/#docker).

`Dockerfile` is a multi-stage build. The default target (`pwpush`) is the web image. Worker and public-gateway variants are additional stages of the same file, so they share layers and are always built from the same commit:

```bash
docker build -f containers/docker/Dockerfile --target pwpush -t pglombardo/pwpush .
docker build -f containers/docker/Dockerfile --target worker -t pglombardo/pwpush-worker .
docker build -f containers/docker/Dockerfile --target public-gateway -t pglombardo/pwpush-public-gateway .
```

Published images on Docker Hub are multi-arch (`linux/amd64` and `linux/arm64`).

Persistent data belongs on `/opt/PasswordPusher/storage` (SQLite at `storage/db/production.sqlite3`). Do not mount a volume over `/opt/PasswordPusher/db` — that path includes `db/migrate/` and overlaying it breaks upgrades. See [DATABASE_URL](https://docs.pwpush.com/docs/database_url/).
