## Build/prerequisites details:
All the builds and tests on host machine were done using rpm packages (no pip packages) :
  - CentOS Linux release 7.4.1708 (Core)
  - docker-client-1.13.1-53.git774336d.el7.centos.x86_64
  - docker-compose-1.9.0-5.el7.noarch (maximum 2.1 template version)

## You can run passwordpusher containerized in many scenarios:

##### passwordpusher-ephemeral
This scenario runs the app in a single container using sqlite3 with no persistent storage (if you recreate the container the data is lost); best if don't care too much about the data and and looking for simplicity in deployment
  - this image works also with openshift/kubernetes (without persistent storage)
  - docker image located here: docker.io/sfarosu/passwordpusher-ephemeral
  - run it with: docker run -p 5000:5000 -d docker.io/sfarosu/passwordpusher-ephemeral

##### passwordpusher-postgres
This scenario uses docker-compose and runs the app using 2 containers on a single host (passwordpusher and postgres); persistent storage for postgres is assured by using a volume on the host machine
  - if you want to change the postgres credentials, change them in Dockerfile (env DATABASE_URL), and in docker-compose file; lastly, rebuild the image then run the updated docker-composer
  - run it with: docker-compose up -d (daemonized)
  - stop it with: docker-compose down
  - your postgres data will be saved on the host machine in /var/lib/postgresql/data

##### passwordpusher-postgres (external database)
If you want to use passwordpusher with an external/existing postgres server, edit in the dockerfile the "DATABASE_URL" env var and rebuild the image (provided you have gave it a proper user / permissions, at first start it will create a new database and it's schema using rake db:migrate/see entrypoint.sh file)
