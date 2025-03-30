# CI/CD Implementation with Terraform and ArgoCD

This project implements a comprehensive CI/CD pipeline for Kubernetes-based microservices using GitHub Actions, Terraform, and ArgoCD.

## Components Implemented

1. **CI Pipeline** (GitHub Actions)
   - Automated building and testing
   - Container image publishing
   - Helm chart value updates

2. **Infrastructure Pipeline** (Terraform)
   - Azure resource provisioning
   - AKS cluster management
   - Environment-specific configurations

3. **CD Pipeline** (ArgoCD)
   - GitOps-based deployments
   - Environment-specific applications
   - Automated/manual sync policies

## Structure

```
kubemicrodemo/
├── .github/
│   └── workflows/
│       ├── ci.yml                # CI pipeline
│       ├── terraform.yml         # Infrastructure pipeline
│       └── argocd-deploy.yml     # ArgoCD deployment
├── argo-cd/
│   ├── applications/
│   │   ├── dev.yaml              # Dev environment app
│   │   └── prod.yaml             # Prod environment app
│   ├── install.yaml              # ArgoCD installation
│   ├── key-vault-csi-driver-installer.yaml
│   ├── project.yaml              # ArgoCD project
│   └── secret-provider.yaml
├── docs/
│   ├── cicd-implementation.md    # Detailed implementation guide
│   ├── github-secrets-setup.md   # Secret setup guide
│   └── README.md                 # This file
├── helm-chart/                   # Application Helm charts
├── terraform/
│   ├── main.tf                   # Main Terraform configuration
│   ├── variables.tf
│   ├── outputs.tf
│   └── environments/             # Environment-specific variables
│       ├── dev/
│       │   └── terraform.tfvars
│       └── prod/
│           └── terraform.tfvars
├── frontend/                     # Application code
├── service-a/
└── service-b/
```

## Getting Started

1. **Set up GitHub repository secrets**
   - See [GitHub Secrets Setup Guide](github-secrets-setup.md)

2. **Deploy infrastructure**
   - Run the Terraform workflow to provision Azure resources
   - Specify environment (dev/prod) and action (plan/apply)

3. **Deploy ArgoCD**
   - Run the ArgoCD deployment workflow
   - This installs ArgoCD and sets up applications

4. **Start development**
   - Push code changes to trigger the CI/CD pipeline
   - ArgoCD will automatically deploy to development
   - Production deployments require manual approval

## Documentation

- [CI/CD Implementation Guide](cicd-implementation.md) - Detailed explanation
- [GitHub Secrets Setup Guide](github-secrets-setup.md) - Secret configuration

## Workflow

1. **Code Changes**
   - Push code → GitHub Actions builds images → Updates Helm values → ArgoCD deploys

2. **Infrastructure Changes**
   - Update Terraform → Create PR → Review plan → Apply changes

## Environments

- **Development** (automatic deployment)
- **Production** (manual approval)

Each environment has its own:
- Kubernetes namespace
- ArgoCD application
- Infrastructure configuration
- Helm values file