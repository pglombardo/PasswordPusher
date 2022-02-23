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

* [pwpush-postgres](https://github.com/pglombardo/PasswordPusher/blob/master/containers/docker/pwpush-postgres/docker-compose.yaml)
* [pwpush-mysql](https://github.com/pglombardo/PasswordPusher/blob/master/containers/docker/pwpush-mysql/docker-compose.yaml)

# Docker Containers

## pwpush-ephemeral

This is a single container that runs independently using sqlite3 with no persistent storage (if you recreate the container the data is lost); best if don't care too much about the data and and looking for simplicity in deployment.

To run an ephemeral version of Password Pusher that saves no data after a container restart:
`docker run -p "8000:5100" pglombardo/pwpush-ephemeral:latest`

_This example is set to listen on port 8000 for requests e.g. http://0.0.0.0:8000._

Available on Docker hub: [pwpush-ephemeral](https://hub.docker.com/repository/docker/pglombardo/pwpush-ephemeral)

## pwpush-postgres

This container uses a default database URL of:

    DATABASE_URL=postgresql://passwordpusher_user:passwordpusher_passwd@postgres:5432/passwordpusher_db

You can either configure your PostgreSQL server to use these credentials or override the environment var in the command line:

    docker run -d -p "5100:5100" -e "DATABASE_URL=postgresql://user:passwd@postgres:5432/my_db" pglombardo/pwpush-postgres:latest

_Note: Providing a postgres password on the command line is far less than ideal_

Available on Docker hub: [pwpush-postgres](https://hub.docker.com/repository/docker/pglombardo/pwpush-postgres)

## pwpush-mysql

This container uses a default database URL of:

    DATABASE_URL=mysql2://passwordpusher_user:passwordpusher_passwd@mysql:3306/passwordpusher_db

You can either configure your MySQL server to use these credentials or override the environment var in the command line:

    docker run -d -p "5100:5100" -e "DATABASE_URL=mysql2://pwpush_user:pwpush_passwd@mysql:3306/pwpush_db" pglombardo/pwpush-mysql:latest

_Note: Providing a postgres password on the command line is far less than ideal_

Available on Docker hub: [pwpush-mysql](https://hub.docker.com/repository/docker/pglombardo/pwpush-mysql)

## Other

### OpenShift

You can run Password Pusher in OpenShift in 2 ways:
  - ephemeral (with no persistent storage): `oc new-app docker.io/pglombardo/pwpush-ephemeral:latest`
  - from an OpenShift template/buildconfig/deploymentconfig and PostgreSQL persistent from the official OpenShift template:
    ```
    oc login https://your_openshift_url
    oc new-project passwordpusher
    cd ~ && git clone https://github.com/pglombardo/PasswordPusher.git && cd ~/PasswordPusher/docker/passwordpusher-openshift
    oc create -f template-with-buildconfig.yaml
    oc new-app postgresql-persistent -p MEMORY_LIMIT=512Mi -p NAMESPACE=openshift -p DATABASE_SERVICE_NAME=postgresql -p POSTGRESQL_USER=passwordpusher_user -p POSTGRESQL_PASSWORD=passwordpusher_passwd -p POSTGRESQL_DATABASE=passwordpusher_db -p VOLUME_CAPACITY=1Gi -p POSTGRESQL_VERSION=9.5
    oc new-app --template=passwordpusher
    ```
OpenShift observations:
- your cluster needs persistent storage for PostgreSQL to save the data
- if you want the Password Pusher template to be available to ALL the projects (Other category in the catalog) in the cluster you need to create the template in the OpenShift namespace: `oc create -f template-with-buildconfig.yaml -n openshift`
- if you want to change the PostgreSQL credentials, modify the `DATABASE_URL` environment variable in the `docker/passwordpusher-openshift/Dockerfile` and also update the credentials when you launch the PostgreSQL installation a few lines above
