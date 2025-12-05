# Password Pusher Metrics Reference

This document lists all Prometheus metrics available in Password Pusher.

## Metrics Overview

Password Pusher exports both **standard Rails metrics** (HTTP requests, database, server) and **custom business metrics** specific to password sharing operations.

## Custom Business Metrics

### Push Lifecycle Metrics

#### `pwpush_pushes_created_total`

Total number of pushes created.

**Labels:**

- `kind` - Type of push: `text`, `file`, `url`, or `qr`
- `user_type` - Creator type: `authenticated` or `anonymous`
- `has_passphrase` - Whether push is passphrase-protected: `yes` or `no`
- `deletable_by_viewer` - Whether viewers can delete: `yes` or `no`
- `retrieval_step` - Whether anti-bot retrieval step is enabled: `yes` or `no`
- `file_count` - Number of files attached (only for file pushes)
- `total_file_size` - Total size in bytes of all files (only for file pushes)

**Example queries:**

```promql
# Total pushes created
sum(pwpush_pushes_created_total)

# Pushes by type
sum by (kind) (pwpush_pushes_created_total)

# Passphrase-protected pushes
sum(pwpush_pushes_created_total{has_passphrase="yes"})

# Anonymous vs authenticated ratio
sum by (user_type) (pwpush_pushes_created_total)
```

#### `pwpush_pushes_viewed_total`

Total number of successful push views.

**Labels:**

- `push_kind` - Type of push: `text`, `file`, `url`, or `qr`
- `user_type` - Viewer type: `authenticated` or `anonymous`
- `had_passphrase` - Whether push was passphrase-protected: `yes` or `no`

**Example queries:**

```promql
# View rate per minute
rate(pwpush_pushes_viewed_total[5m])

# Views by push type
sum by (push_kind) (pwpush_pushes_viewed_total)

# Passphrase-protected views
sum(pwpush_pushes_viewed_total{had_passphrase="yes"})
```

#### `pwpush_pushes_expired_total`

Total number of pushes that have expired.

**Labels:**

- `kind` - Type of push: `text`, `file`, `url`, or `qr`
- `days_lived` - Number of days the push existed before expiration
- `view_count` - Number of times the push was viewed before expiration
- `had_passphrase` - Whether push was passphrase-protected: `yes` or `no`

**Example queries:**

```promql
# Expiration rate
rate(pwpush_pushes_expired_total[1h])

# Average push lifetime
avg(pwpush_pushes_expired_total{days_lived!=""})

# Pushes that expired without being viewed
sum(pwpush_pushes_expired_total{view_count="0"})
```

### Security Metrics

#### `pwpush_pushes_failed_view_total`

Total number of failed view attempts (trying to access expired/deleted pushes).

**Labels:**

- `push_kind` - Type of push: `text`, `file`, `url`, or `qr`
- `user_type` - Viewer type: `authenticated` or `anonymous`
- `reason` - Failure reason: `expired_or_deleted`

**Example queries:**

```promql
# Failed view rate (potential security probing)
rate(pwpush_pushes_failed_view_total[5m])

# Failed views by type
sum by (push_kind) (pwpush_pushes_failed_view_total)
```

**Alert example:**

```yaml
- alert: HighFailedViewRate
  expr: rate(pwpush_pushes_failed_view_total[5m]) > 10
  for: 5m
  annotations:
    summary: "High rate of failed view attempts"
```

#### `pwpush_pushes_failed_passphrase_total`

Total number of failed passphrase attempts.

**Labels:**

- `push_kind` - Type of push: `text`, `file`, `url`, or `qr`
- `user_type` - Viewer type: `authenticated` or `anonymous`

**Example queries:**

```promql
# Failed passphrase rate (brute force detection)
rate(pwpush_pushes_failed_passphrase_total[5m])

# Failed attempts by user type
sum by (user_type) (pwpush_pushes_failed_passphrase_total)
```

**Alert example:**

```yaml
- alert: PassphraseBruteForce
  expr: rate(pwpush_pushes_failed_passphrase_total[1m]) > 5
  for: 2m
  annotations:
    summary: "Potential passphrase brute force attack"
```

### File Upload Metrics

#### `pwpush_file_uploads_total`

Total number of files uploaded.

**Labels:**

- `kind` - Type of push: `file`
- `user_type` - Creator type: `authenticated` or `anonymous`

**Example queries:**

```promql
# File upload rate
rate(pwpush_file_uploads_total[5m])

# Total files uploaded today
increase(pwpush_file_uploads_total[24h])
```

#### `pwpush_file_upload_bytes_total`

Total bytes uploaded in files.

**Labels:**

- `kind` - Type of push: `file`
- `user_type` - Creator type: `authenticated` or `anonymous`

**Example queries:**

```promql
# Upload bandwidth (bytes per second)
rate(pwpush_file_upload_bytes_total[5m])

# Total storage used today (in GB)
increase(pwpush_file_upload_bytes_total[24h]) / 1024 / 1024 / 1024

# Average file size
rate(pwpush_file_upload_bytes_total[5m]) / rate(pwpush_file_uploads_total[5m])
```

### User Authentication Metrics

#### `pwpush_user_signup_total`

Total number of user signups.

**Labels:**

- `locale` - User's preferred language or `default`

**Example queries:**

```promql
# Signup rate
rate(pwpush_user_signup_total[1h])

# Signups by language
sum by (locale) (pwpush_user_signup_total)
```

#### `pwpush_user_login_success_total`

Total number of successful logins.

**Labels:**

- `user_type` - User role: `admin` or `user`

**Example queries:**

```promql
# Login rate
rate(pwpush_user_login_success_total[5m])

# Admin vs regular user logins
sum by (user_type) (pwpush_user_login_success_total)
```

#### `pwpush_user_login_failed_total`

Total number of failed login attempts.

**Labels:**

- `reason` - Failure reason: `invalid_credentials`, etc.

**Example queries:**

```promql
# Failed login rate (security monitoring)
rate(pwpush_user_login_failed_total[5m])

# Failed logins by reason
sum by (reason) (pwpush_user_login_failed_total)

# Login success rate
rate(pwpush_user_login_success_total[5m]) /
(rate(pwpush_user_login_success_total[5m]) + rate(pwpush_user_login_failed_total[5m]))
```

**Alert example:**

```yaml
- alert: HighFailedLoginRate
  expr: rate(pwpush_user_login_failed_total[5m]) > 5
  for: 5m
  annotations:
    summary: "High rate of failed login attempts"
```

#### `pwpush_user_logout_total`

Total number of user logouts.

**Labels:**

- `user_type` - User role: `admin` or `user`

**Example queries:**

```promql
# Logout rate
rate(pwpush_user_logout_total[5m])
```

#### `pwpush_user_locked_total`

Total number of users locked due to too many failed login attempts.

**Labels:**

- `reason` - Lock reason: `too_many_failed_attempts`

**Example queries:**

```promql
# Account lockouts (security incident indicator)
increase(pwpush_user_locked_total[24h])
```

**Alert example:**

```yaml
- alert: AccountLockouts
  expr: increase(pwpush_user_locked_total[1h]) > 3
  for: 5m
  annotations:
    summary: "Multiple account lockouts detected"
```

## Standard Rails Metrics

These metrics are automatically collected by `prometheus_exporter`:

### HTTP Metrics

- `pwpush_http_requests_total{method, status, path}` - Total HTTP requests
- `pwpush_http_request_duration_seconds{method, status, path}` - Request duration histogram

### Database Metrics

- `pwpush_active_record_connection_pool_size` - Connection pool size
- `pwpush_active_record_connection_pool_connections` - Active connections
- `pwpush_active_record_connection_pool_busy` - Busy connections
- `pwpush_active_record_connection_pool_dead` - Dead connections

### Process Metrics

- `pwpush_process_resident_memory_bytes` - Memory usage
- `pwpush_process_cpu_seconds_total` - CPU time

### Puma Metrics

- `pwpush_puma_workers` - Number of Puma workers
- `pwpush_puma_booted_workers` - Number of booted workers
- `pwpush_puma_running_threads` - Number of running threads
- `pwpush_puma_request_backlog` - Request queue depth

## Key Dashboards

### Security Dashboard

```promql
# Failed passphrase attempts rate
rate(pwpush_pushes_failed_passphrase_total[5m])

# Failed login attempts rate
rate(pwpush_user_login_failed_total[5m])

# Failed view attempts rate
rate(pwpush_pushes_failed_view_total[5m])

# Account lockouts in last hour
increase(pwpush_user_locked_total[1h])
```

### Business Metrics Dashboard

```promql
# Total pushes created today
increase(pwpush_pushes_created_total[24h])

# Push creation rate
rate(pwpush_pushes_created_total[5m])

# Pushes by type
sum by (kind) (pwpush_pushes_created_total)

# Anonymous vs authenticated usage
sum by (user_type) (pwpush_pushes_created_total)

# Passphrase adoption rate
sum(pwpush_pushes_created_total{has_passphrase="yes"}) / sum(pwpush_pushes_created_total)
```

### File Upload Dashboard

```promql
# Files uploaded today
increase(pwpush_file_uploads_total[24h])

# Total bytes uploaded today (GB)
increase(pwpush_file_upload_bytes_total[24h]) / 1024 / 1024 / 1024

# Upload bandwidth
rate(pwpush_file_upload_bytes_total[5m])

# Average file size
rate(pwpush_file_upload_bytes_total[5m]) / rate(pwpush_file_uploads_total[5m])
```

### User Engagement Dashboard

```promql
# New signups today
increase(pwpush_user_signup_total[24h])

# Login success rate
rate(pwpush_user_login_success_total[5m]) /
(rate(pwpush_user_login_success_total[5m]) + rate(pwpush_user_login_failed_total[5m]))

# Active sessions (logins - logouts)
increase(pwpush_user_login_success_total[1h]) - increase(pwpush_user_logout_total[1h])
```

### Performance Dashboard

```promql
# 95th percentile response time
histogram_quantile(0.95, rate(pwpush_http_request_duration_seconds_bucket[5m]))

# Request rate
rate(pwpush_http_requests_total[5m])

# Error rate
sum(rate(pwpush_http_requests_total{status=~"5.."}[5m]))

# Memory usage
pwpush_process_resident_memory_bytes

# Database connection pool usage
pwpush_active_record_connection_pool_busy / pwpush_active_record_connection_pool_size
```

## Recommended Alerts

### Security Alerts

```yaml
groups:
  - name: security
    rules:
      - alert: HighFailedPassphraseRate
        expr: rate(pwpush_pushes_failed_passphrase_total[1m]) > 5
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Potential passphrase brute force attack"

      - alert: HighFailedLoginRate
        expr: rate(pwpush_user_login_failed_total[5m]) > 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High rate of failed login attempts"

      - alert: MultipleAccountLockouts
        expr: increase(pwpush_user_locked_total[1h]) > 3
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Multiple account lockouts detected"
```

### Performance Alerts

```yaml
groups:
  - name: performance
    rules:
      - alert: SlowResponseTime
        expr: histogram_quantile(0.95, rate(pwpush_http_request_duration_seconds_bucket[5m])) > 2
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "95th percentile response time above 2s"

      - alert: HighErrorRate
        expr: |
          sum(rate(pwpush_http_requests_total{status=~"5.."}[5m])) /
          sum(rate(pwpush_http_requests_total[5m])) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Error rate above 5%"

      - alert: HighMemoryUsage
        expr: pwpush_process_resident_memory_bytes > 1e9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Memory usage above 1GB"
```

### Business Alerts

```yaml
groups:
  - name: business
    rules:
      - alert: NoActivityDetected
        expr: rate(pwpush_pushes_created_total[1h]) == 0
        for: 2h
        labels:
          severity: info
        annotations:
          summary: "No push creation activity in last 2 hours"

      - alert: HighStorageGrowth
        expr: rate(pwpush_file_upload_bytes_total[1h]) > 1e9
        for: 30m
        labels:
          severity: warning
        annotations:
          summary: "File upload rate exceeding 1GB/hour"
```

## Integration Examples

### Grafana Variable Queries

```promql
# Push types
label_values(pwpush_pushes_created_total, kind)

# User types
label_values(pwpush_pushes_created_total, user_type)

# Locales
label_values(pwpush_user_signup_total, locale)
```

### Recording Rules

```yaml
groups:
  - name: password_pusher_rules
    interval: 1m
    rules:
      # Push success rate (created vs viewed)
      - record: pwpush:push_view_rate:ratio
        expr: |
          sum(rate(pwpush_pushes_viewed_total[5m])) /
          sum(rate(pwpush_pushes_created_total[5m]))

      # Login success rate
      - record: pwpush:login_success_rate:ratio
        expr: |
          sum(rate(pwpush_user_login_success_total[5m])) /
          (sum(rate(pwpush_user_login_success_total[5m])) + sum(rate(pwpush_user_login_failed_total[5m])))

      # Average file size
      - record: pwpush:file_upload:avg_bytes
        expr: |
          rate(pwpush_file_upload_bytes_total[5m]) /
          rate(pwpush_file_uploads_total[5m])
```

## See Also

- [PROMETHEUS.md](PROMETHEUS.md) - Full Prometheus setup documentation
- [Prometheus documentation](https://prometheus.io/docs/)
- [PromQL cheat sheet](https://promlabs.com/promql-cheat-sheet/)
