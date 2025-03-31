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

## Terraform Architecture

The Terraform configuration is split into two parts:

1. **Bootstrap Module** (`terraform/bootstrap/`)
   - Manages the backend infrastructure
   - Creates Azure Storage Account and Container for Terraform state
   - Run once manually before main infrastructure deployment
   - Outputs storage details for GitHub secrets

2. **Main Infrastructure** (`terraform/`)
   - Uses the bootstrap-created storage as backend
   - Manages all application infrastructure (AKS, networking, etc.)
   - Supports multiple environments (dev/prod)
   - Deployed via GitHub Actions

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
│   ├── bootstrap/                # Backend infrastructure setup
│   │   ├── main.tf              # Storage account and container
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── main.tf                   # Main infrastructure
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

1. **Set up Terraform Backend**
   ```bash
   cd terraform/bootstrap
   terraform init
   terraform apply
   ```
   Use the outputs to set GitHub secrets:
   - `TERRAFORM_STORAGE_RG`
   - `TERRAFORM_STORAGE_ACCOUNT`
   - `TERRAFORM_CONTAINER`

2. **Set up GitHub repository secrets**
   - See [GitHub Secrets Setup Guide](github-secrets-setup.md)
   - Add Azure authentication secrets
   - Add Terraform backend secrets from step 1

3. **Deploy infrastructure**
   - Run the Terraform workflow to provision Azure resources
   - Specify environment (dev/prod) and action (plan/apply)

4. **Deploy ArgoCD**
   - Run the ArgoCD deployment workflow
   - This installs ArgoCD and sets up applications

5. **Start development**
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
- Terraform state file in Azure Storage