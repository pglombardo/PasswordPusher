# Running PasswordPusher in a Container

## Build/prerequisites details:
All the builds and tests on host machine were done using rpm packages (no pip packages) :
  - CentOS Linux release 7.4.1708 (Core)
  - docker-client-1.13.1-53.git774336d.el7.centos.x86_64
  - docker-compose-1.9.0-5.el7.noarch (maximum 2.1 template version)

## You can run PasswordPusher in multiple containerized scenarios:

##### passwordpusher-ephemeral
This scenario runs the app in a single container using sqlite3 with no persistent storage (if you recreate the container the data is lost); best if don't care too much about the data and and looking for simplicity in deployment.

  - this image works also with [OpenShift](https://openshift.com/) and [Kubernetes](https://kubernetes.io/) (without persistent storage)
  - docker image located here: [docker.io/pglombardo/pwpush-ephemeral](https://hub.docker.com/r/pglombardo/pwpush-ephemeral/)
  - run it with: `docker run -p 5000:5000 -d docker.io/pglombardo/pwpush-ephemeral`

##### passwordpusher-postgres

This scenario uses `docker-compose` and runs the app using two containers on a single host (passwordpusher and postgres); persistent storage for postgres is assured by using a volume on the host machine.

  - if you want to change the postgres credentials, change them in `Dockerfile` (env `DATABASE_URL`), and in the `docker-compose.yml` file; lastly, rebuild the image then run the updated docker-compose
  - run it with: `docker-compose up -d` (daemonized)
  - stop it with: `docker-compose down`
  - your postgres data will be saved on the host machine in ``/var/lib/postgresql/data`

##### passwordpusher-postgres (external database)

If you want to use PasswordPusher with an external or existing Postgresql server, in the `Dockerfile`, edit `DATABASE_URL` environment variable and rebuild the image

_Provided you provided the correct user credentials, on first boot it will create a new database and it's schema using `rake db:migrate`.  See the `entrypoint.sh` file for details._
