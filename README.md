# GitOps Deployment with ArgoCD on Azure Kubernetes Service (AKS)

👋 Welcome! This repository demonstrates a complete GitOps deployment pipeline using ArgoCD on Azure Kubernetes Service (AKS).

## 🚀 Quick Start Guide

### Prerequisites
- Azure Account ([Get a free account](https://azure.microsoft.com/free/))
- GitHub Account
- Fork this repository: `https://github.com/wahaj4311/3-tier-app.git`
- Azure CLI installed and configured
- `jq` command-line tool installed

## 🔄 Latest Updates

- Improved CI workflow with better error handling and SARIF file management
- Fixed issue with KubeLinter validation
- Added defensive handling of missing artifact files
- Made workflow more resilient to intermittent failures

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

## 🔒 Security and Vulnerability Management

This project includes several security features:

### Vulnerability Scanning
- **Trivy**: We use Aqua Security's Trivy to scan Docker images for vulnerabilities
- **Gitleaks**: Used to detect and prevent secrets being committed to the repository

### Security Measures
- **Docker Image Security**: All Dockerfiles include security updates for critical packages
- **Dependency Management**: Node.js dependencies use version resolutions to enforce patched versions
- **VEX Documentation**: We maintain VEX (Vulnerability Exploitability eXchange) documents in the `.vex` directory

### Maintaining Security
1. **Update Dependencies**:
   ```bash
   # Run the dependency update script
   ./update-dependencies.sh
   ```

2. **Review Vulnerability Reports**:
   - Check the GitHub Actions tab for the latest Trivy and Gitleaks scans
   - Address any findings by updating the relevant files

3. **Secret Management**:
   - Never commit actual secrets to the repository
   - Use the example template files and override values at deployment time
   - Make sure to add secret files to `.gitignore`

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

