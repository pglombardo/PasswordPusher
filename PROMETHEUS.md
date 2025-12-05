# Prometheus Metrics Setup

Password Pusher includes built-in Prometheus metrics export for monitoring and observability.

## Quick Start

Prometheus metrics are integrated into Password Pusher and start automatically with the application.

### 1. Install dependencies

```bash
bundle install
```

### 2. Start the application

```bash
# Development
foreman start -f Procfile.dev

# Production
foreman start
```

The Prometheus exporter starts automatically as part of the application stack.

### 3. Access metrics

Metrics are available at: **`http://localhost:9394/metrics`**

For detailed information about available metrics, see [METRICS.md](METRICS.md).

## Architecture

The Prometheus integration uses `prometheus_exporter` with two components:

1. **Exporter Server Process**: Automatically started via Procfile, collects and serves metrics on port 9394
2. **Client Instrumentation**: Middleware and callbacks in the Rails app that send metrics to the exporter

Both components start automatically when you run `foreman start`.

## Configuration

### Environment Variables

- `PROMETHEUS_EXPORTER_HOST` - Server host (default: `localhost`)
- `PROMETHEUS_EXPORTER_PORT` - Server port (default: `9394`)

Example:

```bash
export PROMETHEUS_EXPORTER_HOST=0.0.0.0
export PROMETHEUS_EXPORTER_PORT=9394
```

### Disable Metrics

Metrics are automatically disabled in test environment. To disable in other environments, remove or comment out the `prometheus` line in your Procfile.

## Prometheus Server Configuration

Add this scrape config to your Prometheus server's `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'password_pusher'
    static_configs:
      - targets: ['localhost:9394']
    scrape_interval: 15s
```

For multiple instances, use service discovery or list multiple targets:

```yaml
scrape_configs:
  - job_name: 'password_pusher'
    static_configs:
      - targets:
          - 'pwpush-1:9394'
          - 'pwpush-2:9394'
          - 'pwpush-3:9394'
    scrape_interval: 15s
```

## Docker Deployment

### Docker Compose

The metrics endpoint needs to be exposed in your `docker-compose.yml`:

```yaml
services:
  app:
    image: pglombardo/pwpush-ephemeral:latest
    environment:
      PROMETHEUS_EXPORTER_HOST: 0.0.0.0
      PROMETHEUS_EXPORTER_PORT: 9394
    ports:
      - "3000:3000"
      - "9394:9394"  # Metrics endpoint
```

The Prometheus exporter process starts automatically via the Procfile.

### Standalone Prometheus Container

```yaml
services:
  app:
    # ... your app config ...

  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    ports:
      - "9090:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'

volumes:
  prometheus-data:
```

## Kubernetes Deployment

### Expose Metrics Port

Update your Deployment to expose the metrics port:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: password-pusher
  labels:
    app: password-pusher
spec:
  ports:
    - name: http
      port: 3000
      targetPort: 3000
    - name: metrics
      port: 9394
      targetPort: 9394
  selector:
    app: password-pusher
```

### ServiceMonitor for Prometheus Operator

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: password-pusher
  labels:
    app: password-pusher
spec:
  selector:
    matchLabels:
      app: password-pusher
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### PodMonitor Alternative

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: password-pusher
spec:
  selector:
    matchLabels:
      app: password-pusher
  podMetricsEndpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

## Troubleshooting

### Metrics not appearing

1. Check that the Prometheus exporter process is running:

   ```bash
   ps aux | grep prometheus_server
   ```

2. Verify the exporter is accessible:

   ```bash
   curl http://localhost:9394/metrics
   ```

3. Check logs in your foreman output for any Prometheus-related errors

4. Ensure you started the app with `foreman start` (not `rails server` alone)

### Port already in use

If port 9394 is already in use, change it:

```bash
export PROMETHEUS_EXPORTER_PORT=9395
```

Then update your Prometheus scrape configuration accordingly.

### Metrics show zero values

- Ensure you've created some pushes and views in the application
- Metrics are counters that start at zero and increment with usage
- Check that the Rails app can connect to the exporter (check `PROMETHEUS_EXPORTER_HOST`)

### Process not starting with foreman

1. Verify the Procfile includes the prometheus line:

   ```bash
   cat Procfile
   ```

2. Check for Ruby/bundle errors:

   ```bash
   bundle exec ruby config/prometheus_server.rb
   ```

### Connection refused errors in logs

The Rails app can't connect to the Prometheus exporter. Check:

1. Exporter is running on the correct port
2. `PROMETHEUS_EXPORTER_HOST` and `PROMETHEUS_EXPORTER_PORT` match between Rails and exporter
3. Firewall rules aren't blocking localhost connections

## Production Recommendations

1. **Always run via Procfile** - Don't start processes manually in production
2. **Monitor the exporter process** - Ensure it stays running (use systemd, supervisord, or k8s health checks)
3. **Secure the metrics endpoint** - Use firewall rules to restrict access to Prometheus servers only
4. **Set appropriate scrape intervals** - 15-30s is usually sufficient, don't scrape too frequently
5. **Use service discovery** - In cloud/k8s environments for automatic target discovery
6. **Bind to correct interface**:
   - Development: `localhost` is fine
   - Production: Use `0.0.0.0` to allow external Prometheus servers
7. **Set up alerts** - Monitor for exporter process failures, high error rates, slow responses
8. **Retention** - Configure Prometheus retention based on your needs (default is 15 days)

## Advanced Configuration

### Custom Metrics

To add your own custom metrics, edit [app/models/concerns/prometheus_metrics.rb](app/models/concerns/prometheus_metrics.rb):

```ruby
# Example: Track custom events
PrometheusMetrics.track_metric("custom_event", {
  category: "example"
})
```

And add the corresponding collector in [config/prometheus_server.rb](config/prometheus_server.rb).

### Alternative Collectors

You can add more collectors for other components:

- Sidekiq metrics (if using Sidekiq instead of SolidQueue)
- Redis metrics
- Custom business metrics
- External service metrics

See the [prometheus_exporter documentation](https://github.com/discourse/prometheus_exporter) for details.

## Documentation

- **[METRICS.md](METRICS.md)** - Complete metrics reference with all available metrics, labels, example queries, dashboards, and alerts
- [prometheus_exporter gem](https://github.com/discourse/prometheus_exporter)
- [Prometheus documentation](https://prometheus.io/docs/)
- [Grafana dashboards](https://grafana.com/grafana/dashboards/)
- [PromQL cheat sheet](https://promlabs.com/promql-cheat-sheet/)
- [Prometheus best practices](https://prometheus.io/docs/practices/)
