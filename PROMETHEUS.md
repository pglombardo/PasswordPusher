# Prometheus metrics

Password Pusher can run an optional Prometheus exporter as a separate process.
It aggregates metrics from Puma workers and the Solid Queue worker and serves
them from `/metrics` on port `9394`.

## Enable metrics

Set:

```shell
PWP__PROMETHEUS__ENABLED=true
PWP__PROMETHEUS__BIND=0.0.0.0
```

The Docker image then starts the `metrics` process. The exporter has no
application authentication and must stay on a private network. Do not publish
port `9394` directly to the internet. The example Compose mapping binds it to
the host loopback interface.

Available settings:

| Environment variable | Default | Purpose |
| --- | --- | --- |
| `PWP__PROMETHEUS__ENABLED` | `false` | Enables instrumentation and the Docker exporter process |
| `PWP__PROMETHEUS__BIND` | `127.0.0.1` | Exporter listen address |
| `PWP__PROMETHEUS__PORT` | `9394` | Exporter listen port |
| `PWP__PROMETHEUS__CLIENT_HOST` | `127.0.0.1` | Exporter address used by app processes |
| `PWP__PROMETHEUS__CLIENT_PORT` | `9394` | Exporter port used by app processes |

For Kubernetes, set `metrics.enabled=true` in the bundled Helm chart. This
adds a dedicated ClusterIP service and standard Prometheus scrape annotations;
it never adds the metrics port to a public application Service. Set
`metrics.scrapeAnnotations=false` when a separately managed PodMonitor or
ServiceMonitor provides discovery.

The separate `pglombardo/pwpush-worker` image also starts its own exporter when
metrics are enabled, so scrape each worker container independently. If an
external exporter is preferred, set `PWP__PROMETHEUS__CLIENT_HOST` to that
private service instead.

## Exported metrics

The exporter provides the standard `prometheus_exporter` Rails metrics,
including:

- `http_requests_total` and `http_request_duration_seconds`
- `active_record_connection_pool_*`
- `puma_*`
- Ruby process, memory, allocation, and garbage-collection metrics

Password Pusher adds:

- `pwpush_pushes_created_total{kind,authenticated}`
- `pwpush_retrievals_total{kind,event}`
- `pwpush_authentication_events_total{event,mfa}`
- `pwpush_uploaded_files_total`
- `pwpush_uploaded_file_bytes_total`

Labels are intentionally bounded. Metrics never include email addresses, user
IDs, IP addresses, push tokens, filenames, expiry values, or payload data.

Metric delivery is asynchronous and fail-open: an unavailable exporter does
not interrupt requests, authentication, or push retrieval.
