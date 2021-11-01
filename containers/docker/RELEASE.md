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

docker tag pglombardo/pwpush-ephemeral:1.10.2 pglombardo/pwpush-ephemeral:release
docker tag pglombardo/pwpush-postgres:1.10.2 pglombardo/pwpush-postgres:release
docker tag pglombardo/pwpush-mysql:1.10.2 pglombardo/pwpush-mysql:release