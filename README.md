<div align="center">

[![Password Pusher](https://pwpush.fra1.cdn.digitaloceanspaces.com/branding/logos/horizontal-logo-small.png)](https://pwpush.com/)

**Share passwords, text, files & URLs securely with self-deleting links and full audit logs.**

[![Try it free](https://img.shields.io/badge/Try_it_free-pwpush.com-0ea5e9?style=for-the-badge)](https://pwpush.com)
[![Documentation](https://img.shields.io/badge/Docs-docs.pwpush.com-64748b?style=for-the-badge)](https://docs.pwpush.com)

[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/pglombardo/PasswordPusher/ruby-tests.yml?branch=master)](https://github.com/pglombardo/PasswordPusher/actions/workflows/ruby-tests.yml)
[![GitHub stars](https://img.shields.io/github/stars/pglombardo/PasswordPusher)](https://github.com/pglombardo/PasswordPusher)
[![Docker pulls](https://img.shields.io/docker/pulls/pglombardo/pwpush)](https://hub.docker.com/r/pglombardo/pwpush)
[![License](https://img.shields.io/github/license/pglombardo/PasswordPusher)](https://github.com/pglombardo/PasswordPusher/blob/master/LICENSE)

</div>

---

## What is Password Pusher?

**Password Pusher** is an open source web app for sharing sensitive information safely. You push a password, note, file, or URL; the recipient gets a one-time link that expires after a set number of views and/or time. No more sending secrets over chat or email—everything is encrypted, auditable, and can self-destruct.

Use the [hosted service](https://pwpush.com) or run your own instance with Docker in minutes.

---

## Why Password Pusher?

| | |
|---|---|
| **🔒 Secure by default** | Encrypted storage, optional passphrase, expiry by views and/or time. Sensitive data is removed entirely once expired. |
| **📋 Full audit trail** | See when links were created, viewed, and by whom (with logins). |
| **🏠 Self-host or use hosted** | Use [pwpush.com](https://pwpush.com) or deploy your own—Docker, Kubernetes, Helm, or cloud. |
| **🌐 Ready for teams** | 31 languages, light/dark theme, JSON API, CLI, and [many integrations](https://docs.pwpush.com/docs/3rd-party-tools/). |

---

## Features

### Security & privacy

- **Encrypted at rest** — Sensitive data is stored encrypted and deleted when expired.
- **Expiry controls** — Limit by number of views and/or time; links can require a passphrase.
- **Audit logging** — Track what was shared and who viewed it (with optional logins).
- **Unbranded delivery page** — No logos, superfluous text or unrelated links to confuse push recipients.

### Self-host & customize

- **One-command deploy** — Docker Compose with automatic SSL/TLS
- **Database or ephemeral** — Use a database for persistence or run stateless.
- **Admin dashboard** — Manage your instance from a built-in admin UI.
- **White-label** — Custom theme, logo, site name, and [26 Bootswatch themes](https://docs.pwpush.com/docs/themes/) via env vars.
- **Custom CSS** — Add your own styles; light/dark follows system preference.

### Integrations & API

- **JSON API** — Integrate with scripts, `curl`, `wget`, or third-party tools.
- **CLI** — Automate distribution with [CLI tools](https://docs.pwpush.com/docs/3rd-party-tools/) and scripts.
- **31 languages** — UI and secret-URL pages in 31 languages (courtesy of [Translation.io](https://translation.io/?utm_source=pwpush)).

### Trust & community

- **Open source** — Apache 2.0; no black box. Written and maintained by [myself](https://github.com/pglombardo) and the team at [Apnotic](https://apnotic.com) with the help of contributors.
- **14+ years in production** — Used to deliver millions of secrets; [actively maintained](https://github.com/pglombardo/PasswordPusher/graphs/contributors).
- **Trusted worldwide** — Used by thousands of companies around the globe.

---

## Screenshots

| [![Front page](app/assets/images/features/front-page-thumb.png)](app/assets/images/features/front-page-large.png) | [![Audit log](app/assets/images/features/audit-log-thumb.png)](app/assets/images/features/audit-log-large.png) | [![Languages](app/assets/images/features/secret-url-languages-thumb.png)](app/assets/images/features/secret-url-languages-large.png) |
|:---:|:---:|:---:|
| **Create a push** | **Audit log** | **Multi-language URLs** |

| [![Password generator](app/assets/images/features/password-generator-thumb.png)](app/assets/images/features/password-generator-large.png) | [![Dark theme](app/assets/images/features/dark-theme-thumb.png)](app/assets/images/features/dark-theme.gif) | [![Preliminary step](app/assets/images/features/preliminary-step-thumb.png)](app/assets/images/features/preliminary-step.gif) |
|:---:|:---:|:---:|
| **Password generator** | **Dark theme** | **Optional preview step** |

---

## Editions

| | **Open source (this repo)** | **Pro (pwpush.com)** |
|---|---|---|
| **Try it** | [oss.pwpush.com](https://oss.pwpush.com) | [pwpush.com](https://pwpush.com) |
| **Use case** | Self-host or use OSS demo | Hosted Pro with extra features |
| **Details** | Full source here; you deploy or use the OSS demo. | Pro features are [periodically migrated](https://docs.pwpush.com/docs/editions/) to OSS. |

**Feature comparison:** [pwpush.com/features#matrix](https://pwpush.com/features#matrix)

### Self-Hosted Password Pusher Pro (beta)

Self-hosted **Pro** (with licensing) is in early beta. Pro features not yet in OSS will be available for self-hosted deployments.

- [Join the waitlist](https://waitlister.me/p/self-hosted-pro?utm_source=github&utm_medium=social&utm_campaign=self_hosted_pro_waitlist) for availability and beta access.
- **Waitlist subscribers get 20% off** their first year’s Self-Hosted Pro license at launch.

---

## Quick Start

### Use the hosted service

No setup: **[pwpush.com](https://pwpush.com)** — create a push and share the link.

### Run your own instance with Docker Compose

1. Point a DNS record to your server (e.g. `pwpush.example.com`).
2. Clone this repo or download [docker-compose.yml](https://raw.githubusercontent.com/pglombardo/PasswordPusher/refs/heads/master/docker-compose.yml).
3. In `docker-compose.yml`, uncomment and set:
   - `TLS_DOMAIN: 'pwpush.example.com'` (for automatic Let’s Encrypt TLS).
   - Optionally set `PWPUSH_MASTER_KEY` (see comments in the file; generate at [us.pwpush.com/generate_key](https://us.pwpush.com/generate_key)).
4. Run:

```bash
docker compose up -d
```

Open `https://pwpush.example.com`. The Compose file includes persistent storage, health checks, and is suitable for production.

### Use the API, CLI, or integrations

See [3rd party tools & integrations](https://docs.pwpush.com/docs/3rd-party-tools/) for API usage, CLIs, and integrations.

---

## Documentation

Full docs: **[docs.pwpush.com](https://docs.pwpush.com)** — installation, configuration, API, themes, and more.

---

## Language translations

**[Translation.io](https://translation.io/?utm_source=pwpush)** has provided free translation tooling for the OSS version of Password Pusher. The app ships with **31 UI languages**.

[![Translation.io](app/assets/images/partners/translation-io-banner.png)](https://translation.io/?utm_source=pwpush)

Consider [Translation.io](https://translation.io/?utm_source=pwpush) for your company or project’s translation needs.

---

## Credits

### Security researchers

- **Kullai Metikala** — [GitHub](https://github.com/kullaisec) \| [LinkedIn](https://www.linkedin.com/in/kullai-metikala-8378b122a/)
- [Positive Technologies](https://global.ptsecurity.com)
- **Igniter** — [GitHub](https://github.com/igniter07)

### Translators

| Name | Language |
|------|----------|
| [Oyale](https://github.com/oyale) | [Catalan](https://pwpush.com/ca), [Spanish](https://pwpush.com/es) |
| Finn Skaaning | [Danish](https://pwpush.com/da/p/ny) |
| [Mihail Tchetchelnitski](https://github.com/mtchetch) | [Finnish](https://pwpush.com/fi/p/uusi) |
| [Thibaut](https://github.com/tibo59) | [French](https://pwpush.com/fr/p/Nouveau) |
| Thomas Wölk | [German](https://pwpush.com/de/p/neu) — [GitHub](https://github.com/confluencepoint), [Twitter](https://twitter.com/confluencepoint) |
| Martin Otto | [German](https://pwpush.com/de/p/neu) |
| Robin Jørgensen | [Norwegian](https://pwpush.com/no/p/ny) |
| [Łukasz](https://github.com/drpt) | [Polish](https://pwpush.com/pl/p/nowy) |
| [Jair Henrique](https://github.com/jairhenrique/), [Fabrício Rodrigues](https://www.linkedin.com/in/ifabriciorodrigues/), [Ivan Freitas](https://github.com/IvanMFreitas), Sara Faria | [Portuguese (BR)](https://pwpush.com/pt-br/p/novo) |
| Pedro Marques | [European Portuguese](https://pwpush.com/pt-pt/p/novo) |
| johan323, Fredrik Arvas | [Swedish](https://pwpush.com/sv/p/ny) |

Thanks also to [Translation.io](https://translation.io) for managing translations (free for open source).

### Containers & infrastructure

- [@fiskhest](https://github.com/fiskhest) — [Kubernetes manifests](https://github.com/pglombardo/PasswordPusher/tree/master/containers/kubernetes)
- [@sfarosu](https://github.com/sfarosu) — [Docker, Kubernetes & OpenShift support](https://github.com/pglombardo/PasswordPusher/pull/82)
- [sirux88](https://github.com/sirux88) — Docker cleanup and multistage builds

### Other

- [@iandunn](https://github.com/iandunn) — Password form security
- [Kasper Grubbe](https://github.com/kaspergrubbe) — [JSON POST fix](https://github.com/pglombardo/PasswordPusher/pull/3)
- [JarvisAndPi](http://www.reddit.com/user/JarvisAndPi) — Favicon design

More: [Contributors](https://github.com/pglombardo/PasswordPusher/graphs/contributors)

---

## Stay updated

- **Newsletter** — [Sign up](https://buttondown.email/pwpush?tag=github) for release notes, security updates, and tips.
- **Social** — [X](https://x.com/pwpush), [Reddit](https://www.reddit.com/r/pwpush), [Facebook](https://www.facebook.com/pwpush)

---

## Donations

Donations are **optional**. Password Pusher is and will remain open source and free to use.

If it’s useful to you and you’d like to support development, donations are greatly appreciated and go toward hosting, maintenance, testing, and new features.

| [![Donate QR](https://pwpush.fra1.cdn.digitaloceanspaces.com/misc/pwpush-donate-stripe-qr-small.png)](https://buy.stripe.com/7sI4gCgTT1tr6WY3cd) | [**Donate via Stripe**](https://buy.stripe.com/7sI4gCgTT1tr6WY3cd) |
|---|---|

You can also support the project with a [paid plan on pwpush.com](https://pwpush.com/pricing).

**Note:** Password Pusher is operated by Apnotic, LLC. Donations support the project but are not tax-deductible charitable contributions. See [FAQ](https://docs.pwpush.com/docs/faq/) for more on [Apnotic](https://docs.pwpush.com/docs/faq/#what-is-apnotic) and [trust & security](https://docs.pwpush.com/docs/faq/#trust-is-a-concern--why-should-i-trust-and-use-password-pusher).

---

## Star history

[![Star History Chart](https://api.star-history.com/svg?repos=pglombardo/PasswordPusher&type=Date)](https://www.star-history.com/#pglombardo/PasswordPusher&Date)

---

## License

This project is licensed under the **Apache License 2.0**. See [LICENSE](https://github.com/pglombardo/PasswordPusher/blob/master/LICENSE) for details.

---

## Citation

```bibtex
@misc{PasswordPusher,
  author = {Peter Giacomo Lombardo},
  title = {Password Pusher: Securely share sensitive information with automatic expiration and deletion. Track who, what and when with full audit logs.},
  year = {2026},
  publisher = {GitHub},
  howpublished = {\url{https://github.com/pglombardo/PasswordPusher}}
}
```
