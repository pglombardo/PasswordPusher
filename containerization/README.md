# Running PasswordPusher in a Container

All container images are available on Docker hub: [hub.docker.com/u/pglombardo/](https://hub.docker.com/u/pglombardo/)

## Build/prerequisites details:
All the builds and tests on host machine were done using rpm packages (no pip packages) :
  - CentOS Linux release 7.4.1708 (Core)
  - docker-client-1.13.1-53.git774336d.el7.centos.x86_64
  - docker-compose-1.9.0-5.el7.noarch (maximum 2.1 template version)

## You can run PasswordPusher in multiple containerized scenarios:

##### pwpush-ephemeral
This scenario runs the app in a single container using sqlite3 with no persistent storage (if you recreate the container the data is lost); best if don't care too much about the data and and looking for simplicity in deployment.

  - this image works also with [OpenShift](https://openshift.com/) and [Kubernetes](https://kubernetes.io/) (without persistent storage)
  - docker image located here: [docker.io/pglombardo/pwpush-ephemeral](https://hub.docker.com/r/pglombardo/pwpush-ephemeral/)
  - run it with: `docker run -p 5000:5000 -d docker.io/pglombardo/pwpush-ephemeral`

[https://hub.docker.com/r/pglombardo/pwpush-ephemeral/](https://hub.docker.com/r/pglombardo/pwpush-ephemeral/)

##### pwpush-postgres

This scenario uses `docker-compose` and runs the app using two containers on a single host (passwordpusher and postgres); persistent storage for postgres is assured by using a volume on the host machine.

  - if you want to change the postgres credentials, change them in `Dockerfile` (env `DATABASE_URL`), and in the `docker-compose.yml` file; lastly, rebuild the image then run the updated docker-compose
  - run it with: `docker-compose up -d` (daemonized)
  - stop it with: `docker-compose down`
  - your postgres data will be saved on the host machine in ``/var/lib/postgresql/data`

[https://hub.docker.com/r/pglombardo/pwpush-postgres/](https://hub.docker.com/r/pglombardo/pwpush-postgres/)

##### pwpush-postgres (external database)

If you want to use PasswordPusher with an external or existing Postgresql server, in the `Dockerfile`, edit `DATABASE_URL` environment variable and rebuild the image

Example:

    DATABASE_URL=postgresql://user:pw@host:5432/db

_Provided you provided the correct user credentials, on first boot it will create a new database and it's schema using `rake db:migrate`.  See the `entrypoint.sh` file for details._

[https://hub.docker.com/r/pglombardo/pwpush-postgres/](https://hub.docker.com/r/pglombardo/pwpush-postgres/)

##### pwpush-openshift

You can run passwordpusher in openshift in 2 ways:
  - ephemeral (with no persistent storage): `oc new-app docker.io/pglombardo/pwpush-ephemeral:1.0`
  - from an openshift template/buildconfig/deploymentconfig and postgresql persistent from the official openshift template:
    ```
    oc login https://your_openshift_url
    oc new-project passwordpusher
    cd ~ && git clone https://github.com/pglombardo/PasswordPusher.git && cd ~/PasswordPusher/containerization/passwordpusher-openshift
    oc create -f template-with-buildconfig.yaml
    oc new-app postgresql-persistent -p MEMORY_LIMIT=512Mi -p NAMESPACE=openshift -p DATABASE_SERVICE_NAME=postgresql -p POSTGRESQL_USER=passwordpusher_user -p POSTGRESQL_PASSWORD=passwordpusher_passwd -p POSTGRESQL_DATABASE=passwordpusher_db -p VOLUME_CAPACITY=1Gi -p POSTGRESQL_VERSION=9.5
    oc new-app --template=passwordpusher
    ```
OpenShift observations:
- your cluster needs persistent storage for postgresql to save the data
- if you want the passwordpusher template to be available to ALL the projects (Other category in the catalog) in the cluster you need to create the template in the openshift namespace: `oc create -f template-with-buildconfig.yaml -n openshift`
- if you want to change the postgresql credentials, modify the DATABASE_URL env variable in the ~/PasswordPusher/containerization/passwordpusher-openshift/dockerfile and also update the credentials when you launch the postgresql installation a few lines above
