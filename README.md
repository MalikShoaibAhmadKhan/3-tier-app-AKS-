# GitOps Deployment with ArgoCD on Azure Kubernetes Service (AKS)

👋 Welcome! This repository demonstrates a complete GitOps deployment pipeline using ArgoCD on Azure Kubernetes Service (AKS).

## 🚀 Quick Start Guide

### Prerequisites
- Azure Account ([Get a free account](https://azure.microsoft.com/free/))
- GitHub Account
- Fork this repository: `https://github.com/wahaj4311/3-tier-app.git`

### One-Time Setup

1. **Create Azure Service Principal**
```bash
# Set your preferred service principal name
SP_NAME="your-sp-name-$(date +%s)"  # Replace 'your-sp-name' with your preferred name

az login
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

# Print the values
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
   - Creates AKS cluster
   - Sets up required infrastructure
   - Creates storage for Terraform state (if not exists)
   - Automatically triggers ArgoCD deployment

2. **CI Pipeline** (GitHub Actions → CI Pipeline)
   - Automatically runs on code changes
   - Builds and pushes Docker images
   - Updates application deployments

## 📚 Additional Resources

- [Architecture Overview](docs/architecture.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Cleanup Instructions](docs/cleanup.md)

## 🤝 Contributing

Feel free to open issues or submit pull requests for improvements.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

