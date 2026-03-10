# Upgrading to Password Pusher 2.0 (OSS)

Password Pusher **2.0 is the current release line** on `master`. The **primary changes in 2.0** are aimed at **better defaults** and an **easier first run** for new self-hosters—less to configure before the app is useful, with clearer opt-ins where operators want stricter or email-dependent behavior. This guide summarizes **high-level changes** from **1.x to 2.0** and what you should adjust when upgrading an existing instance.

For full configuration reference, see [Self-hosted configuration](https://docs.pwpush.com/docs/self-hosted-configuration/).

**Primary installation method:** Self-hosted deployments are expected to use [docker-compose.yml](https://github.com/pglombardo/PasswordPusher/blob/master/docker-compose.yml) at the repository root. In 2.0 this file was **reorganized to be easier to read**: it documents **all configurable options** in one place, each behind a comment so you can **uncomment and set values** to enable or disable features without hunting through `config/settings.yml` first.

---

## Summary of what changed

### 1. **Logins are always on; `enable_logins` is removed**

- **Before (1.x):** `enable_logins` toggled whether user accounts existed at all. URL/file/QR pushes were often documented as requiring logins.
- **After (2.0):** User accounts and authentication are **always available**. There is no `Settings.enable_logins` and no `PWP__ENABLE_LOGINS` setting.
- **What you control instead:**
  - **`allow_anonymous`** – if `false`, creating new pushes (and related flows) requires a logged-in user; secret link retrieval for existing pushes remains as before.
  - **`disable_signups`** – still used to block new registrations while keeping logins for existing users.

**Upgrade action:** Remove any `PWP__ENABLE_LOGINS` (or `enable_logins`) from your environment or config; it is obsolete. Use `allow_anonymous` and `disable_signups` to match your desired policy.

---

### 2. **Devise email flows are opt-in: `enable_user_account_emails`**

- **Before (1.x):** With logins enabled, Devise commonly expected mail for confirm / reset / unlock depending on setup.
- **After (2.0):** **Email-based Devise modules are disabled by default.** When `enable_user_account_emails` is `false` (default), the app does **not** load `:confirmable`, `:lockable`, or `:recoverable`. That means:
  - No confirmation emails on signup
  - No “forgot password” email flow
  - No unlock-by-email after lockout

- **When `enable_user_account_emails` is `true`:** Those modules are enabled **only if** you have a working SMTP configuration in `config/settings.yml` (Mail section). Enabling without working mail will break signup, password reset, and unlock flows.

**Upgrade action:** If you already run SMTP and rely on confirmation, password reset, or unlock emails, set:

```yaml
enable_user_account_emails: true
```

Or via environment:

```bash
PWP__ENABLE_USER_ACCOUNT_EMAILS=true
```

Ensure `host_domain`, `host_protocol` (and mailer sender / SMTP) are set so links in emails are correct.

---

### 3. **Feature toggles: URL, file, and QR pushes default to on**

- **Before (1.x):** `enable_url_pushes`, `enable_file_pushes`, and `enable_qr_pushes` defaulted to `false` and were tied to “logins enabled” in docs.
- **After (2.0):** Defaults are **`true`** for URL, file, and QR pushes. They are no longer gated by a login toggle; access for **creating** pushes when anonymous is allowed is controlled by **`allow_anonymous`** and the respective enable flags.

**Upgrade action:**

- If you **want** URL/file/QR pushes: ensure storage/backends (e.g. file storage) are configured; defaults may already turn features on.
- If you **do not** want them: set the relevant flags to `false` explicitly (same env names as before, e.g. `PWP__ENABLE_URL_PUSHES=false`).

---

### 4. **Push defaults: retrieval step defaults**

- **Before (1.x):** `retrieval_step_default` for password, URL, and file pushes was commonly `false` in defaults.
- **After (2.0):** Defaults are **`true`** for password, URL, and file pushes (QR remains `false` in defaults). New pushes created via the JSON API without an explicit `retrieval_step` will follow these settings.

**Upgrade action:** If you depend on the old behavior (no extra retrieval step by default), set the per-kind `retrieval_step_default` back to `false` in `config/settings.yml` or via the documented `PWP__PW__RETRIEVAL_STEP_DEFAULT` (and URL/files equivalents).

---

### 5. **GDPR consent banner default**

- **Before (1.x):** `show_gdpr_consent_banner` defaulted to `true`.
- **After (2.0):** Defaults to **`false`**.

**Upgrade action:** If you still need the banner, set `show_gdpr_consent_banner: true` (or the corresponding env override).

---

### 6. **Settings file layout and Docker Compose**

- **Settings:** `config/settings.yml` (and `config/defaults/settings.yml`) were reorganized into clearer sections (deployment/URL, feature toggles, authentication, mail, per-push-kind). **Semantic keys changed** in places (e.g. removal of `enable_logins`, addition of `enable_user_account_emails`). Merging an old file blindly may leave obsolete keys or miss new ones—compare against the new defaults file.
- **Docker Compose:** Example compose in the repo uses the **2.0** image line and documents `PWP__ENABLE_USER_ACCOUNT_EMAILS`. Remove any leftover `PWP__ENABLE_LOGINS` from your own compose/env files.

**Upgrade action:** Diff your current `config/settings.yml` against `config/defaults/settings.yml` in 2.0 and migrate env vars to the new names where applicable.

---

### 7. **UI and static pages**

- Dashboard, push forms, preview, audit, about, API token page, encryption key generator, and HTTP error pages were restyled for consistency. No special migration is required unless you override views in a fork—re-test custom overrides after upgrade.

---

## Minimal upgrade checklist

1. **Backup** DB and `config/settings.yml` (and any mounted secrets).
2. **Remove** `enable_logins` / `PWP__ENABLE_LOGINS` from config and environment.
3. **Decide on email:** If you use SMTP for account emails, set **`enable_user_account_emails: true`** and verify mail delivery before going live.
4. **Decide on anonymous access:** Set **`allow_anonymous`** and **`disable_signups`** to match your policy.
5. **Reconcile feature flags:** Explicitly set URL/file/QR and storage if you don’t want the new defaults.
6. **Reconcile push defaults:** Set **`retrieval_step_default`** per kind if you need the old default.
7. **GDPR banner:** Turn back on if required.
8. **Run migrations** if the release includes any (follow release notes for the exact tag).
9. **Smoke-test:** Login, create text/url/file/qr push, JSON API with token, and first-run/boot if applicable.

---

## Quick reference: important settings (2.0)

| Area | Setting | Default (2.0) | Notes |
|------|---------|---------------|--------|
| Auth | *(removed)* | — | `enable_logins` removed |
| Auth | `allow_anonymous` | `true` | `false` = logged-in only for creating pushes (per app logic) |
| Auth | `disable_signups` | `false` | Block new registrations |
| Mail / Devise | `enable_user_account_emails` | `false` | `true` + SMTP required for confirm/reset/unlock |
| Features | `enable_url_pushes` | `true` | Set `false` to disable |
| Features | `enable_file_pushes` | `true` | Configure storage if enabled |
| Features | `enable_qr_pushes` | `true` | Set `false` to disable |
| Push defaults | `pw/url/files retrieval_step_default` | `true` | QR default remains `false` in defaults |
| Privacy | `show_gdpr_consent_banner` | `false` | Set `true` to show banner |

Environment overrides follow the usual `PWP__...` pattern; each variable is listed with a short comment in [docker-compose.yml](https://github.com/pglombardo/PasswordPusher/blob/master/docker-compose.yml).

---

## Further reading

- [Self-hosted configuration](https://docs.pwpush.com/docs/self-hosted-configuration/)
