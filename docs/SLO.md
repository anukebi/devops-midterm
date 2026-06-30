# Service Level Objectives

Availability and reliability targets for this project. These define what "working correctly" looks like for local
development and deployment.

## Availability targets

| Component                   | Target                     | How it's checked                              |
|-----------------------------|----------------------------|-----------------------------------------------|
| Application (`/api/health`) | Stays up during normal use | `pipeline/healthcheck.sh`, Docker healthcheck |
| Blue-green deployment       | Completes without rollback | `pipeline/deploy.sh` exits successfully       |
| CI pipeline (`main`)        | Passes on push             | GitHub Actions workflow status                |

## Error thresholds

**Application errors** - alert fires when more than 5 errors occur in one minute:

```
increase(app_errors_total[1m]) > 5
```

This is expected when testing `/api/error` or running `./scripts/trigger-alert.sh`.

**Deployment downtime** - health check retries 5 times with a 5-second interval (up to ~25 seconds per deploy).
Blue-green deployment keeps downtime limited to this window.

**Rollback** - if a deploy fails, rollback should restore the previous version within ~10 seconds (2 health check
cycles), provided the other slot was healthy.

## Metrics to monitor

| Metric / check     | Source                          | Problem indicator                     |
|--------------------|---------------------------------|---------------------------------------|
| `app_errors_total` | Prometheus, Grafana             | More than 5 errors per minute         |
| HTTP health check  | `pipeline/healthcheck.sh`       | Non-200 after 5 retries               |
| JVM / HTTP metrics | Grafana -> Application Services | Unexpected spikes                     |
| Error logs         | Kibana (`level: ERROR`)         | Errors outside of intentional testing |

## Monitoring setup

- **Metrics** - Prometheus scrapes `/actuator/prometheus` every 5 seconds
- **Logs** - JSON logs via Logstash -> Elasticsearch -> Kibana (Docker mode)
- **Dashboards** - Grafana: Application Services, Infrastructure & Resources, System Overview
- **Alerts** - high error rate rule in both Prometheus and Grafana
