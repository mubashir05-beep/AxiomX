# Helm Chart: Trading Engine

This is a production-ready Helm chart for deploying the AxiomX trading engine on Kubernetes.

## Quick Start

```bash
# Install
helm install axiomx-trading . --namespace trading --values values.yaml

# Upgrade
helm upgrade axiomx-trading . --namespace trading --values values.yaml

# Rollback
helm rollback axiomx-trading

# Uninstall
helm uninstall axiomx-trading --namespace trading
```

## Chart Structure

```
.
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values
├── templates/
│   ├── deployment.yaml     # Application deployment
│   ├── service.yaml        # ClusterIP + headless services
│   ├── hpa.yaml            # Horizontal Pod Autoscaler
│   ├── configmap.yaml      # Application configuration
│   ├── secret.yaml         # Sensitive data references
│   ├── servicemonitor.yaml # Prometheus scraping
│   ├── pdb.yaml            # Pod Disruption Budget
│   ├── rbac.yaml           # ServiceAccount, Role, RoleBinding
│   ├── _helpers.tpl        # Template helpers
│   └── NOTES.txt           # Post-install messages
└── README.md               # This file
```

## Values Configuration

### Deployment Settings

```yaml
# Number of replicas
replicaCount: 3

# Container image
image:
  repository: axiomx-trading-engine
  tag: latest
  pullPolicy: IfNotPresent

# Resource allocation
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

# Pod affinity (spread across nodes)
podAntiAffinity: required
```

### Scaling Settings

```yaml
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  
  # Target metrics
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
  
  # Scale-up policy (fast response)
  scale_up_period: 30s
  scale_up_percent: 100
  
  # Scale-down policy (conservative)
  scale_down_period: 300s
  scale_down_percent: 50
```

### Health Probes

```yaml
probes:
  # Detects dead container (restart if needed)
  liveness:
    enabled: true
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3
  
  # Prevents traffic to not-ready pod
  readiness:
    enabled: true
    initialDelaySeconds: 10
    periodSeconds: 5
    timeoutSeconds: 3
    failureThreshold: 3
  
  # Allows slow startup completion
  startup:
    enabled: true
    initialDelaySeconds: 0
    periodSeconds: 10
    timeoutSeconds: 3
    failureThreshold: 30  # 5 minutes for startup
```

### Environment Variables

```yaml
environment:
  LOG_LEVEL: "info"
  ENVIRONMENT: "production"
  METRICS_PORT: "8080"
  PPROF_ENABLED: "false"
  REQUEST_TIMEOUT: "30s"
  MAX_ORDER_SIZE: "1000000"
  MAX_POSITION_SIZE: "10000000"

# Secrets (from Kubernetes Secret)
secrets:
  DATABASE_URL: "database-secret"
  KAFKA_BROKERS: "kafka-secret"
  REDIS_ADDR: "redis-secret"
  REDIS_PASSWORD: "redis-password-secret"
```

### Monitoring

```yaml
monitoring:
  # Prometheus scraping
  servicemonitor:
    enabled: true
    interval: 30s
    scrape_path: /metrics
  
  # CloudWatch integration
  cloudwatch:
    enabled: true
    log_group: "/axiomx/trading-engine"
```

### Security

```yaml
security:
  # Pod Security
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  
  # Pod Disruption Budget
  podDisruptionBudget:
    enabled: true
    minAvailable: 2
```

## Custom Values

Create `custom-values.yaml` to override defaults:

```yaml
replicaCount: 5

image:
  tag: v1.2.3

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

autoscaling:
  maxReplicas: 20
  targetCPUUtilizationPercentage: 60

environment:
  LOG_LEVEL: "debug"
  ENVIRONMENT: "staging"

ingress:
  enabled: true
  hosts:
    - axiomx.example.com
```

Then deploy:
```bash
helm install axiomx-trading . --namespace trading --values custom-values.yaml
```

## Helm Template Rendering

### View Generated Manifests

```bash
# Render all templates
helm template axiomx-trading . --namespace trading

# Render specific template
helm template axiomx-trading . --namespace trading -s templates/deployment.yaml

# Render with custom values
helm template axiomx-trading . --namespace trading -f custom-values.yaml
```

### Validate Syntax

```bash
# Lint chart
helm lint . --strict

# Validate Kubernetes manifests
helm template axiomx-trading . | kubectl apply --dry-run=client -f -
```

## Upgrading the Chart

### Minor Version Upgrade

```bash
# Check what will change
helm diff upgrade axiomx-trading . --namespace trading

# Apply upgrade (rolling restart)
helm upgrade axiomx-trading . --namespace trading

# View upgrade status
helm status axiomx-trading -n trading
kubectl rollout status deployment/trading-engine -n trading
```

### Scaling Up Manually

```bash
# Scale deployment
kubectl scale deployment trading-engine -n trading --replicas=5

# Or via Helm values
helm upgrade axiomx-trading . \
  --namespace trading \
  --set replicaCount=5
```

### Updating Image

```bash
# Deploy new version
helm upgrade axiomx-trading . \
  --namespace trading \
  --set image.tag=v1.2.4
```

## Troubleshooting

### Chart Validation Failed

```bash
# Check chart structure
helm lint .

# Validate generated manifests
helm template axiomx-trading . | kubectl apply --dry-run=client -f -

# Detailed error output
helm template axiomx-trading . --debug
```

### Pod Not Starting

```bash
# Check pod events
kubectl describe pod -n trading -l app=trading-engine

# View logs
kubectl logs -n trading -l app=trading-engine --tail=100

# Check resource availability
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### Deployment Stuck in Rolling Update

```bash
# Check rollout history
kubectl rollout history deployment/trading-engine -n trading

# View current status
kubectl rollout status deployment/trading-engine -n trading

# Rollback if needed
kubectl rollout undo deployment/trading-engine -n trading
```

## Advanced Usage

### Helm Hooks

Pre/post-install/upgrade operations:

```yaml
---
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ include "trading-engine.fullname" . }}-db-migrate"
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-weight": "-5"
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        command: ["/app/migrate.sh"]
```

### Conditional Features

Enable/disable components via values:

```yaml
# In templates/hpa.yaml
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
...
{{- end }}
```

### Environment-Specific Deployments

```bash
# Development
helm install axiomx-trading . \
  --namespace trading-dev \
  --values values-dev.yaml

# Staging
helm install axiomx-trading . \
  --namespace trading-staging \
  --values values-staging.yaml

# Production
helm install axiomx-trading . \
  --namespace trading-prod \
  --values values-prod.yaml
```

## Best Practices

1. **Use OCI Registry**: Store charts in artifact registry
   ```bash
   helm registry login ociregistry.azurecr.io
   helm push . ociregistry.azurecr.io/axiomx-trading-engine:1.0.0
   ```

2. **Version Control**: Track `Chart.yaml` version and app version
   ```yaml
   version: 1.0.0  # Chart version (increment on release)
   appVersion: "v1.2.3"  # Application version (matches image tag)
   ```

3. **Semantic Versioning**: Follow MAJOR.MINOR.PATCH
   - PATCH: Bug fixes, dependency updates
   - MINOR: New features (backward compatible)
   - MAJOR: Breaking changes

4. **Values Schema Validation**: Add JSON schema
   ```yaml
   # In Chart.yaml
   kubeVersion: ">=1.28.0"
   ```

5. **Documentation**: Keep README + In-code comments updated

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Deploy Trading Engine

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Helm lint
        run: helm lint infrastructure/helm/
      
      - name: Deploy to EKS
        run: |
          aws eks update-kubeconfig --name axiomx-prod
          helm upgrade --install axiomx-trading infrastructure/helm/ \
            --namespace trading \
            --values infrastructure/helm/values-prod.yaml
      
      - name: Verify deployment
        run: |
          kubectl rollout status deployment/trading-engine -n trading
          kubectl get pods -n trading
```

## References

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/)
- [Chart Best Practices](https://helm.sh/docs/chart_best_practices/)

