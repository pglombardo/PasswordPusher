# Password Pusher & Docker Container

# Docker Container
Available on Docker Hub: [pwpush](https://hub.docker.com/r/pglombardo/pwpush)

## Supported database backends

| Backend | Description|
|-|-|
| **ephemeral** | SQLite3 backed container that runs alone.  All data is lost after a container restart. This is set by default|
| **postgres** | Postgres backed container that can be pointed to a pre-existing database instance using an environment variable (`DATABASE_URL`).|
| **mysql** | MySQL or Mariadb backed container that can be pointed to a pre-existing database instance using an environment variable (`DATABASE_URL`).|

## ephemeral

This configuration runs independently using sqlite3 with no persistent storage (if you recreate the container the data is lost); best if don't care too much about the data and looking for simplicity in deployment.

To run an ephemeral version of Password Pusher that saves no data after a container restart:
`docker run -p "8000:5100" pglombardo/pwpush:latest`

_This example is set to listen on port 8000 for requests e.g. http://0.0.0.0:8000._

See also this discussion if you want to persist data across container restarts: [How to Add Persistence?](https://github.com/pglombardo/PasswordPusher/discussions/448)
(Since this link refers to an outdated ephemeral image keep in mind to use current image `pglombardo/pwpush`)

## postgres

To setup the container to use the PostgreSQL database backend DATABASE_URL environment variable needs to be configured. The syntax should look like:

    DATABASE_URL=postgresql://passwordpusher_user:passwordpusher_passwd@postgres:5432/passwordpusher_db

You can either configure your PostgreSQL server to use these credentials or override the environment variable in the command line:

    docker run -d -p "5100:5100" -e "DATABASE_URL=postgresql://user:passwd@postgres:5432/my_db" pglombardo/pwpush:latest

### Better Security with Password Files

Providing a PostgreSQL password on the command line such as in the preceeding is less than ideal.  The Postgres Docker image also supports the idea of password files.

See [this section on Docker Secrets](https://github.com/docker-library/docs/blob/master/postgres/README.md#docker-secrets) on how to avoid passing credentials on the command line.  Further, also [consider this example](https://github.com/pglombardo/PasswordPusher/issues/412) provided by [Viajaz](https://github.com/Viajaz).


## mysql

To setup the container to use the MariaDB/MySQL database backend DATABASE_URL environment variable needs to be configured. The syntax should look like:

    DATABASE_URL=mysql2://passwordpusher_user:passwordpusher_passwd@mysql:3306/passwordpusher_db

You can either configure your MariaDB/MySQL server to use these credentials or override the environment var in the command line:

    docker run -d -p "5100:5100" -e "DATABASE_URL=mysql2://pwpush_user:pwpush_passwd@mysql:3306/pwpush_db" pglombardo/pwpush:latest

_Note: Providing a MariaDB/MySQL password on the command line is far less than ideal_


## Tags

| Tag Name | Description |
|-|-|
| `latest` | Builds off of the latest code.  May occasionally be unstable. |
| `release` | Points to the latest _stable_ release. |
| `X.X.X` | Semantic version tags. |

When in doubt, use `release`.

## Platforms
The docker container is available for `linux/amd64` and `linux/arm64` platforms.

# Docker Compose

For a quick boot of a database backed application, see the available Docker Compose files:
* [ephemeral](https://github.com/pglombardo/PasswordPusher/blob/master/containers/docker/docker-compose-ephemeral.yml)
* [postgres](https://github.com/pglombardo/PasswordPusher/blob/master/containers/docker/docker-compose-postgres.yml)
* [mysql](https://github.com/pglombardo/PasswordPusher/blob/master/containers/docker/docker-compose-mysql.yml)
* [mariadb](https://github.com/pglombardo/PasswordPusher/blob/master/containers/docker/docker-compose-mariadb.yml)
