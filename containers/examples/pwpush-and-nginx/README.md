See the [documentation](https://docs.pwpush.com/docs/installation/#nginx) on how to run Password Pusher with nginx.

## Large file uploads

The example `nginx.conf` is sized for the default `PWP__FILES__MAX_FILE_SIZE=100GB` and `PWP__FILES__MAX_FILE_UPLOADS=10`:

- `client_max_body_size 1T` — this is an **aggregate request** limit, not a per-file cap. Nginx defaults it to `1m` (413). JSON API and through-Puma uploads send every file in one body, so 10 × 100GB plus multipart framing needs more than 100G. Direct-to-storage PUTs do not use this limit.
- `proxy_request_buffering off` — stream the upload to Password Pusher instead of spooling it on the proxy.
- `client_body_timeout`, `proxy_connect_timeout`, `proxy_send_timeout`, and `proxy_read_timeout` of 3600s — large transfers can sit idle between chunks.

Web **direct uploads** to S3, GCS, or Azure go from the browser to the storage provider. Those PUTs do not pass through this proxy, so nginx body limits only affect:

- local disk storage (`PWP__FILES__STORAGE=local`)
- JSON API file attachments (the file is in the app request body)
- the small `POST /pfb/direct_uploads` that creates the blob before a direct upload

### Thruster (Docker `bin/web`)

Official images put Thruster in front of Puma. Thruster defaults:

- `HTTP_IDLE_TIMEOUT=60`
- `HTTP_READ_TIMEOUT=30`
- `HTTP_WRITE_TIMEOUT=30`
- `MAX_REQUEST_BODY=0` (unlimited)

For large files routed through Puma/Thruster, raise the timeouts, for example:

```bash
HTTP_IDLE_TIMEOUT=3600
HTTP_READ_TIMEOUT=3600
HTTP_WRITE_TIMEOUT=3600
```

(`THRUSTER_`-prefixed names work too.)

### Cloudflare

Cloudflare's free/pro HTTP body limit is 100MB. Direct-to-object-storage uploads bypass that because the PUT goes to the bucket host, not through Cloudflare. Local-disk and JSON API uploads that pass through Cloudflare cannot exceed 100MB unless you are on a plan that raises that cap, or you skip Cloudflare for those routes.
