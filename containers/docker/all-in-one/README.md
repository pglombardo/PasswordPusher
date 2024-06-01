# Password Pusher - All In One Setup

The files in this directory allow you to launch a Password Pusher instance with automatic SSL/TLS certificate
management thanks to Caddy server & Let's Encrypt.

Caddy is a proxy that when given a domain, will automatically fetch, update & monitor TSL
certificates for that domain in tandem with Let's Encrypt.

# Prerequisites

To run this, you will need both Docker and Docker Compose installed.

# How to Run

1. Open `docker-compose-pwpush.yml` and follow the instructions inside.

2. Open `Caddyfile` and do the same.

3. Run `docker-compose -f docker-compose-pwpush.yml`
