# Incident Response

What to do when something breaks. For availability targets and alert thresholds, see [SLO.md](SLO.md).

## Deployment health check fails

**Signs:** `pipeline/healthcheck.sh` exits with an error, or `/api/health` does not return HTTP 200.

```bash
curl http://localhost:8080/api/health
```

**Automatic rollback:**

`pipeline/deploy.sh` runs a health check after every deploy. If it fails, the script rolls back automatically:

1. Ansible redeploys the previous blue/green slot (`skip_build=true`)
2. Health check runs again
3. `deployment-current` symlink points to whichever slot is healthy

**If rollback doesn't work:**

1. Check `deployment-blue/output.log` or `deployment-green/output.log`
2. Verify the process is running: `ps aux | grep midterm.jar`
3. Start the jar manually from the last working color directory
4. Re-run `bash pipeline/healthcheck.sh`

Common causes: port already in use, jar not copied correctly, app crash on startup.

## High error rate alert

**Signs:** `HighErrorRate` alert in Prometheus or Grafana - fires when more than 5 errors happen in one minute.

**Check first:** If `/api/error` or `./scripts/trigger-alert.sh` was used recently, the alert is expected. Wait about a
minute for it to clear.

**Otherwise:**

1. Grafana alerts: http://localhost:3000/alerting/list
2. Kibana logs filtered by `level: ERROR`
3. If a recent deploy caused it - switch `DEPLOYMENT_COLOR` in `~/devops/env` and run `pipeline/deploy.sh`
4. If a code change caused it - revert the commit and push to `main`

## CI/CD pipeline failure

**Signs:** GitHub Actions workflow fails on push or PR.

Open the failed run and check which job broke:

| Job          | Fix                                                      |
|--------------|----------------------------------------------------------|
| `test`       | Run `./mvnw test` locally, fix failing tests             |
| `checkstyle` | Run `mvn checkstyle:check`, fix reported issues          |
| `gitleaks`   | Remove exposed secrets from the repository               |
| `trivy`      | Update Docker base image or dependencies with known CVEs |
| `tfsec`      | Fix issues in `pipeline/terraform/`                      |

## Observability stack down

**Signs:** Grafana, Prometheus, or Kibana not loading.

Restart the stack:

```bash
docker compose down && docker compose up -d --build
```

Or:

```bash
bash scripts/setup.sh --docker-only
```

If Kibana loads but shows no logs, Elasticsearch may still be starting. Check with:

```bash
curl http://localhost:9200/_cluster/health
```

Elasticsearch can take a minute to become ready after a fresh start.

## Manual recovery

If automated rollback and the steps above don't help:

1. Stop running new deployments
2. Manually start the jar from the last known good blue/green directory
3. Check logs in the deployment directory for the root cause

## After recovery

Verify everything is back to normal:

```bash
curl http://localhost:8080/api/health
bash scripts/validate-environment.sh
```

Check Grafana dashboards to confirm metrics and alerts look correct.
