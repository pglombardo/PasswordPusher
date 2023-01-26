# Password Pusher & Docker Containers

## Container Types

| Container Name | Description|
|-|-|
| **pwpush-ephemeral** | SQLite3 backed container that runs alone.  All data is lost after a container restart.|
| **pwpush-postgres** | Postgres backed container that can be pointed to a pre-existing database instance using an environment variable (`DATABASE_URL`).|
| **pwpush-mysql** | MySQL or Mariadb backed container that can be pointed to a pre-existing database instance using an environment variable (`DATABASE_URL`).|

## Tags

| Tag Name | Description |
|-|-|
| `latest` | Builds off of the latest code.  May occasionally be unstable. |
| `release` | Points to the latest _stable_ release. |
| `X.X.X` | Semantic version tags. |

When in doubt, use `release`.

`amd64` and `arm64` architectures are both built.  Note [this bug](https://github.com/pglombardo/PasswordPusher/issues/268) in regards to tag availability for the `arm64` architecture.

# Docker Compose

For a quick boot of a database backed application, see the available Docker Compose files:

* [pwpush-postgres](https://github.com/pglombardo/PasswordPusher/blob/master/containers/docker/pwpush-postgres/docker-compose.yml)
* [pwpush-mysql](https://github.com/pglombardo/PasswordPusher/blob/master/containers/docker/pwpush-mysql/docker-compose.yml)

# Docker Containers

## pwpush-ephemeral

This is a single container that runs independently using sqlite3 with no persistent storage (if you recreate the container the data is lost); best if don't care too much about the data and and looking for simplicity in deployment.

To run an ephemeral version of Password Pusher that saves no data after a container restart:
`docker run -p "8000:5100" pglombardo/pwpush-ephemeral:latest`

_This example is set to listen on port 8000 for requests e.g. http://0.0.0.0:8000._

Available on Docker hub: [pwpush-ephemeral](https://hub.docker.com/repository/docker/pglombardo/pwpush-ephemeral)

See also this discussion if you want to persist data across container restarts: [pwpush-ephemeral: How to Add Persistence?](https://github.com/pglombardo/PasswordPusher/discussions/448)

## pwpush-postgres

This container uses a default database URL of:

    DATABASE_URL=postgresql://passwordpusher_user:passwordpusher_passwd@postgres:5432/passwordpusher_db

You can either configure your PostgreSQL server to use these credentials or override the environment var in the command line:

    docker run -d -p "5100:5100" -e "DATABASE_URL=postgresql://user:passwd@postgres:5432/my_db" pglombardo/pwpush-postgres:latest

Available on Docker hub: [pwpush-postgres](https://hub.docker.com/repository/docker/pglombardo/pwpush-postgres)

### Better Security with Password Files

Providing a PostgreSQL password on the command line such as in the preceeding is less than ideal.  The Postgres Docker image also supports the idea of password files.

See [this section on Docker Secrets](https://github.com/docker-library/docs/blob/master/postgres/README.md#docker-secrets) on how to avoid passing credentials on the command line.  Further, also [consider this example](https://github.com/pglombardo/PasswordPusher/issues/412) provided by [Viajaz](https://github.com/Viajaz).


## pwpush-mysql

This container uses a default database URL of:

    DATABASE_URL=mysql2://passwordpusher_user:passwordpusher_passwd@mysql:3306/passwordpusher_db

You can either configure your MySQL server to use these credentials or override the environment var in the command line:

    docker run -d -p "5100:5100" -e "DATABASE_URL=mysql2://pwpush_user:pwpush_passwd@mysql:3306/pwpush_db" pglombardo/pwpush-mysql:latest

_Note: Providing a MySQL password on the command line is far less than ideal_

Available on Docker hub: [pwpush-mysql](https://hub.docker.com/repository/docker/pglombardo/pwpush-mysql)
