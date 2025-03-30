# CI/CD Implementation Guide

This guide explains the complete CI/CD implementation using GitHub Actions, Terraform, and ArgoCD.

## Architecture Overview

Our CI/CD pipeline combines:

1. **GitHub Actions** for Continuous Integration (CI)
2. **Terraform** for Infrastructure as Code (IaC)
3. **ArgoCD** for GitOps-based Continuous Delivery (CD)

This approach follows the modern GitOps principles, where:
- Infrastructure is defined as code (Terraform)
- Application configurations are stored in Git (Helm charts)
- ArgoCD ensures the cluster state matches the desired state in Git

## CI/CD Workflow

### 1. Development Workflow

1. Developer pushes code changes
2. GitHub Actions builds, tests, and pushes new container images
3. GitHub Actions updates Helm chart values with new image tags
4. ArgoCD detects changes in Git and updates applications in the cluster

### 2. Infrastructure Changes

1. Infrastructure team updates Terraform files
2. GitHub Actions runs Terraform plan/apply
3. Terraform provisions/updates Azure resources
4. ArgoCD configuration is updated as needed

## Pipeline Components

### 1. CI Pipeline (GitHub Actions)

The CI pipeline handles:
- Building and testing application code
- Publishing container images to GitHub Container Registry
- Updating Helm chart values with new image tags

Workflow file: `.github/workflows/ci.yml`

### 2. Infrastructure Pipeline (GitHub Actions + Terraform)

The infrastructure pipeline handles:
- Provisioning and updating Azure resources
- Creating AKS clusters
- Setting up database services
- Configuring networking

Workflow file: `.github/workflows/terraform.yml`

### 3. CD Pipeline (ArgoCD)

ArgoCD handles:
- Detecting changes in Helm charts and application manifests
- Synchronizing the Kubernetes cluster with desired state
- Automated rollouts for development environments
- Manual approval for production environments

Workflow file: `.github/workflows/argocd-deploy.yml`

## Environment Management

We maintain separate environments for development and production:

### Development Environment
- Automatic deployments
- Self-healing configuration
- Uses `values-local.yaml` for Helm chart values

### Production Environment 
- Manual approval for sync
- Uses `values-prod.yaml` for Helm chart values
- Higher resource allocations

## Getting Started

### 1. Prerequisites

Before you begin, ensure you have:
- Azure subscription
- GitHub repository
- Required secrets configured (see `docs/github-secrets-setup.md`)

### 2. Initial Setup

1. Run the Terraform workflow to provision infrastructure
```bash
# Trigger the Terraform workflow
gh workflow run terraform.yml -f environment=dev -f action=apply
```

2. Deploy ArgoCD to the cluster
```bash
# Trigger the ArgoCD deployment workflow
gh workflow run argocd-deploy.yml -f environment=all
```

### 3. Ongoing Operations

#### Deploying Application Changes

Simply push changes to the application code, and the CI pipeline will automatically:
1. Build and publish new container images
2. Update Helm chart values
3. ArgoCD will detect the changes and update the applications

#### Making Infrastructure Changes

1. Update Terraform files
2. Create a pull request
3. Review the Terraform plan
4. Merge to apply the changes

## Monitoring and Maintenance

### ArgoCD Dashboard

Access the ArgoCD dashboard to monitor application deployments:
```bash
# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then access the UI at https://localhost:8080

### GitHub Actions Logs

Monitor CI/CD pipeline runs in the GitHub Actions tab of your repository.

## Troubleshooting

### Common Issues

1. **ArgoCD sync failures**
   - Check application logs in ArgoCD UI
   - Ensure Helm charts are valid
   - Verify Kubernetes resources are correctly defined

2. **Terraform failures**
   - Check Terraform state
   - Verify Azure permissions
   - Review resource constraints

3. **CI failures**
   - Check Docker build logs
   - Verify application tests
   - Ensure GitHub Container Registry access

## Security Considerations

1. **Secret Management**
   - Secrets are stored in GitHub Secrets
   - Azure Key Vault is used for application secrets

2. **Authentication**
   - Service Principal or OIDC for Azure authentication
   - ArgoCD admin password is auto-generated

3. **Network Security**
   - Azure network policies
   - Kubernetes network policies

## Best Practices

1. **Always use Pull Requests** for code changes
2. **Review Terraform plans** before applying
3. **Monitor ArgoCD sync status** in the dashboard
4. **Use semantic versioning** for application releases
5. **Enable automated tests** in the CI pipeline
6. **Document infrastructure changes** in commit messages