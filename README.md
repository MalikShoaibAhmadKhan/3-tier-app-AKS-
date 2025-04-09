# GitOps Deployment with ArgoCD on Azure Kubernetes Service (AKS)

👋 Welcome! This repository demonstrates a complete GitOps deployment pipeline using ArgoCD on Azure Kubernetes Service (AKS).

## 🚀 Quick Start Guide

### Prerequisites
- Azure Account ([Get a free account](https://azure.microsoft.com/free/))
- GitHub Account
- Fork this repository: `https://github.com/wahaj4311/3-tier-app.git`
- Azure CLI installed and configured
- `jq` command-line tool installed

### One-Time Setup

1. **Create Azure Service Principal**
   ```bash
   # Set your preferred service principal name
   SP_NAME="your-sp-name-$(date +%s)"  # Replace 'your-sp-name' with your preferred name

   # Login to Azure
   az login

   # Create service principal
   az ad sp create-for-rbac --name "$SP_NAME" \
     --role contributor \
     --scopes /subscriptions/<your-subscription-id> \
     --sdk-auth > sp_output.json
   ```

2. **Extract Service Principal Information**
   ```bash
   # Extract values from sp_output.json
   AZURE_CLIENT_ID=$(cat sp_output.json | jq -r .clientId)
   AZURE_CLIENT_SECRET=$(cat sp_output.json | jq -r .clientSecret)
   AZURE_TENANT_ID=$(cat sp_output.json | jq -r .tenantId)
   AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

   # Print the values (copy these for GitHub Secrets)
   echo "AZURE_CLIENT_ID: $AZURE_CLIENT_ID"
   echo "AZURE_CLIENT_SECRET: $AZURE_CLIENT_SECRET"
   echo "AZURE_TENANT_ID: $AZURE_TENANT_ID"
   echo "AZURE_SUBSCRIPTION_ID: $AZURE_SUBSCRIPTION_ID"
   ```

3. **Add GitHub Secrets**
   Go to your repository Settings → Secrets and variables → Actions → New repository secret and add:
   - From the extracted values above:
     - `AZURE_CLIENT_ID`
     - `AZURE_CLIENT_SECRET`
     - `AZURE_TENANT_ID`
     - `AZURE_SUBSCRIPTION_ID`
   - Application:
     - `DB_USERNAME`: Your database username
     - `DB_PASSWORD`: Your database password

### Deployment Steps

1. **Deploy Infrastructure** (GitHub Actions → Deploy to AKS)
   - Navigate to the "Actions" tab in your repository
   - Select "Deploy to AKS" workflow
   - Click "Run workflow"
   - The workflow will:
     - Create AKS cluster
     - Set up required infrastructure
     - Create storage for Terraform state
     - Automatically trigger ArgoCD deployment

2. **CI Pipeline** (GitHub Actions → CI Pipeline)
   - Automatically runs on code changes to:
     - `frontend/**`
     - `service-a/**`
     - `service-b/**`
     - `helm-chart/**`
     - `README.md`
   - Builds and pushes Docker images
   - Updates application deployments

## 🏗️ Architecture Overview

![Architecture Diagram](architecture.png)

The architecture includes the following components:

- **Azure Kubernetes Service (AKS)**: Managed Kubernetes cluster on Azure
- **ArgoCD**: GitOps continuous delivery tool that automates the deployment of applications to Kubernetes
- **Azure Key Vault**: Secure storage for secrets
- **Terraform**: Infrastructure as Code tool to provision Azure resources
- **GitHub Actions**: CI/CD pipeline to build and deploy the application

## 📚 Additional Resources

- [Architecture Overview](docs/architecture.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Cleanup Instructions](docs/cleanup.md)

## 🤝 Contributing

Feel free to open issues or submit pull requests for improvements.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 

