# Upgrading to Password Pusher 2.0 (OSS)

2.0 is the current release on `master`. It focuses on **better defaults** and **less setup for new installs**. If you already run 1.x, you only need to act where your **old config or expectations** conflict with the new defaults—everything else can stay as-is.

**Config reference:** [Self-hosted configuration](https://docs.pwpush.com/docs/self-hosted-configuration/)  
**Env vars & compose:** [docker-compose.yml](https://github.com/pglombardo/PasswordPusher/blob/master/docker-compose.yml) (primary install path; all `PWP__...` options are commented there)

---

## Required steps for existing deployments

Do these in order; skip any step that does not apply to you.


| #   | Action                                                                                                                                                                                                                                  | When                                  |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| 1   | **Backup** database and any custom config/secrets.                                                                                                                                                                                      | Always                                |
| 2   | **Remove** `PWP__ENABLE_LOGINS` and any `enable_logins` in YAML. The setting no longer exists.                                                                                                                                          | Always if you had it set              |
| 3   | **If you rely on email** (signup confirmation, forgot password, unlock): set `PWP__ENABLE_USER_ACCOUNT_EMAILS=true` (or `enable_user_account_emails: true`) **and** confirm SMTP works. If you leave it off, those flows stay disabled. | Only if you used Devise mail before   |
| 4   | **If you do not want** URL/file/QR pushes or the new retrieval-step default: set the relevant env vars to `false` explicitly (see docker-compose comments). 2.0 defaults several features **on** that were **off** in 1.x.              | Only if defaults are too open for you |
| 5   | **Smoke-test** after deploy: login, create a push, API with token if you use it.                                                                                                                                                        | Always                                |


That’s the minimum. If nothing broke and behavior is acceptable, you’re done.

---

## Optional (only if you need it)

- **Anonymous vs logged-in only:** Use `PWP__ALLOW_ANONYMOUS` and `PWP__DISABLE_SIGNUPS` to match policy (replaces the old “logins off” mental model).
- **GDPR banner:** Off by default in 2.0. Set `PWP__SHOW_GDPR_CONSENT_BANNER=true` if you still need it.
- **Custom `settings.yml`:** Still works. Prefer **environment variables** for new changes—see docker-compose. Long term, file-based config may move toward an in-app UI; env-based config is the forward-compatible path. 
- **Fork with view overrides:** UI was restyled; re-test any customized templates.

---

## What changed (reference)

Use this only if you need context or to diff behavior.


| Topic                      | 1.x                                     | 2.0                                                        |
| -------------------------- | --------------------------------------- | ---------------------------------------------------------- |
| **Logins**                 | `enable_logins` could turn accounts off | Always on; use `allow_anonymous` / `disable_signups`       |
| **Devise email**           | Often assumed when logins were on       | **Opt-in** via `enable_user_account_emails` + SMTP         |
| **URL / file / QR pushes** | Default off, tied to logins in docs     | Default **on**; turn off explicitly if unwanted            |
| **Retrieval step default** | Default off for pw/url/files            | Default **on** for pw/url/files (QR stays off in defaults) |
| **GDPR banner**            | Default on                              | Default **off**                                            |
| **Configuration**          | Many used `settings.yml` only           | **Preferred:** env vars in compose; YAML still supported   |


---

## Quick settings table


| Setting                                                         | Default (2.0) | Set to match old behavior                    |
| --------------------------------------------------------------- | ------------- | -------------------------------------------- |
| `enable_user_account_emails`                                    | `false`       | `true` + working SMTP if you need mail flows |
| `allow_anonymous`                                               | `true`        | `false` to require login to create pushes    |
| `enable_url_pushes` / `enable_file_pushes` / `enable_qr_pushes` | `true` each   | `false` to disable                           |
| `pw` / `url` / `files` → `retrieval_step_default`               | `true`        | `false` for no extra step by default         |
| `show_gdpr_consent_banner`                                      | `false`       | `true` to show banner                        |


All of the above have `PWP__...` equivalents—see [docker-compose.yml](https://github.com/pglombardo/PasswordPusher/blob/master/docker-compose.yml).

---

## Further reading

- [Self-hosted configuration](https://docs.pwpush.com/docs/self-hosted-configuration/)

