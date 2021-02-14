# Running PasswordPusher in a Container

All container images are available on Docker hub: [hub.docker.com/u/pglombardo/](https://hub.docker.com/u/pglombardo/)

## tldr

To run an ephemeral version that saves no data on port 8000:
`docker run -p "8000:5000" pglombardo/pwpush-ephemeral:latest`

To run a version with postgres, use [this docker-compose.yml file](https://github.com/pglombardo/PasswordPusher/blob/master/containerization/pwpush-postgres/docker-compose.yaml).

For everything else, read on...

## Build/prerequisites details:
All the builds and tests on host machine were done using rpm packages (no pip packages) :
  - CentOS Linux release 7.4.1708 (Core)
  - docker-client-1.13.1-53.git774336d.el7.centos.x86_64
  - docker-compose-1.9.0-5.el7.noarch (maximum 2.1 template version)

## You can run PasswordPusher in multiple containerized scenarios:

##### pwpush-ephemeral
This scenario runs the app in a single container using sqlite3 with no persistent storage (if you recreate the container the data is lost); best if don't care too much about the data and and looking for simplicity in deployment.

  - this image works also with [OpenShift](https://openshift.com/) and [Kubernetes](https://kubernetes.io/) (without persistent storage)
  - Docker image located here: [docker.io/pglombardo/pwpush-ephemeral](https://hub.docker.com/r/pglombardo/pwpush-ephemeral/)
  - run it with: `docker run -p 5000:5000 -d docker.io/pglombardo/pwpush-ephemeral`

[https://hub.docker.com/r/pglombardo/pwpush-ephemeral/](https://hub.docker.com/r/pglombardo/pwpush-ephemeral/)

##### pwpush-postgres

This scenario uses `docker-compose` and runs the app using two containers on a single host (PasswordPusher and PostgreSQL); persistent storage for PostgreSQL is assured by using a volume on the host machine.

  - if you want to change the PostgreSQL credentials, change them in `Dockerfile` (env `DATABASE_URL`), and in the `docker-compose.yml` file; lastly, rebuild the image then run the updated docker-compose
  - run it with: `docker-compose up -d` (daemonized)
  - stop it with: `docker-compose down`
  - your PostgreSQL data will be saved on the host machine in ``/var/lib/postgresql/data`

[https://hub.docker.com/r/pglombardo/pwpush-postgres](https://hub.docker.com/r/pglombardo/pwpush-postgres)

##### pwpush-postgres (external database)

This container uses a default database URL of:

    DATABASE_URL=postgresql://passwordpusher_user:passwordpusher_passwd@postgres:5432/passwordpusher_db
    
You can either configure your PostgreSQL server to use these credentials or override the environment var in the command line:

    docker run -d -p "5000:5000" -e "DATABASE_URL=postgresql://user:passwd@postgres:5432/my_db" pglombardo/pwpush-postgres:latest
    
_Note: Providing a postgres password on the command line is far less than ideal_

Lastly, you can also rebuild the container image from Dockerfile.  See `Dockerfile` and the `entrypoint.sh` files in the `pwpush-postgres` folder.

[https://hub.docker.com/r/pglombardo/pwpush-postgres](https://hub.docker.com/r/pglombardo/pwpush-postgres)

##### pwpush-openshift

You can run PasswordPusher in OpenShift in 2 ways:
  - ephemeral (with no persistent storage): `oc new-app docker.io/pglombardo/pwpush-ephemeral:1.0`
  - from an OpenShift template/buildconfig/deploymentconfig and PostgreSQL persistent from the official OpenShift template:
    ```
    oc login https://your_openshift_url
    oc new-project passwordpusher
    cd ~ && git clone https://github.com/pglombardo/PasswordPusher.git && cd ~/PasswordPusher/containerization/passwordpusher-openshift
    oc create -f template-with-buildconfig.yaml
    oc new-app postgresql-persistent -p MEMORY_LIMIT=512Mi -p NAMESPACE=openshift -p DATABASE_SERVICE_NAME=postgresql -p POSTGRESQL_USER=passwordpusher_user -p POSTGRESQL_PASSWORD=passwordpusher_passwd -p POSTGRESQL_DATABASE=passwordpusher_db -p VOLUME_CAPACITY=1Gi -p POSTGRESQL_VERSION=9.5
    oc new-app --template=passwordpusher
    ```
OpenShift observations:
- your cluster needs persistent storage for PostgreSQL to save the data
- if you want the PasswordPusher template to be available to ALL the projects (Other category in the catalog) in the cluster you need to create the template in the OpenShift namespace: `oc create -f template-with-buildconfig.yaml -n openshift`
- if you want to change the PostgreSQL credentials, modify the `DATABASE_URL` environment variable in the `containerization/passwordpusher-openshift/Dockerfile` and also update the credentials when you launch the PostgreSQL installation a few lines above
