# Container Release Cheat Sheet

cd pwpush-postgres

docker build --no-cache -t pglombardo/pwpush-postgres:<version> .

docker push pglombardo/pwpush-postgres:<version>

docker tag <tag> pglombardo/pwpush-postgres:latest

docker push pglombardo/pwpush-postgres:latest

cd pwpush-ephemeral
docker build --no-cache -t pglombardo/pwpush-ephemeral:<version> .
docker push pglombardo/pwpush-ephemeral:<version>
docker tag <tag> pglombardo/pwpush-ephemeral:latest
docker push pglombardo/pwpush-ephemeral:latest