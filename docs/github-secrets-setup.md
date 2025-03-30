# GitHub Secrets Setup Guide

This guide explains how to set up the necessary GitHub repository secrets for our CI/CD pipeline.

## Required Secrets

The following secrets need to be configured in your GitHub repository:

### Azure Authentication

These secrets are used for authenticating with Azure:

- `AZURE_CLIENT_ID`: Service principal client ID
- `AZURE_TENANT_ID`: Azure tenant ID
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID
- `AZURE_CLIENT_SECRET`: Service principal secret

### Terraform Backend

These secrets are used for configuring the Terraform backend:

- `TERRAFORM_STORAGE_RG`: Resource group for Terraform state storage
- `TERRAFORM_STORAGE_ACCOUNT`: Storage account for Terraform state
- `TERRAFORM_CONTAINER`: Storage container for Terraform state

### Database Credentials

Used by Terraform to provision Azure database services:

- `DB_USERNAME`: Database admin username
- `DB_PASSWORD`: Database admin password

### Kubernetes Cluster

These are populated automatically after Terraform creates the AKS cluster, but can be set manually if needed:

- `AKS_RESOURCE_GROUP`: Resource group containing the AKS cluster
- `AKS_CLUSTER_NAME`: Name of the AKS cluster

### GitHub Integration

For workflows that need to trigger other workflows:

- `WORKFLOW_DISPATCH_TOKEN`: GitHub Personal Access Token (PAT) with `workflow` scope

## Creating the Service Principal

Run the following commands to create a service principal with Contributor role:

```bash
# Create a service principal with Contributor role
az ad sp create-for-rbac --name "GitHubActionsSP" \
                       --role Contributor \
                       --scopes /subscriptions/{subscription-id} \
                       --sdk-auth
```

This will output a JSON object containing the credentials needed for the secrets.

## Setting up GitHub Secrets

1. Go to your GitHub repository
2. Click on "Settings"
3. Click on "Secrets and variables" → "Actions"
4. Click on "New repository secret"
5. Add each of the required secrets with their corresponding values
6. Click "Add secret" after each one

## Setting up Terraform Backend Resources

```bash
# Create resource group
az group create --name terraform-state-rg --location eastus

# Create storage account
az storage account create --name tfstate$(uuidgen | cut -c1-8) --resource-group terraform-state-rg --sku Standard_LRS

# Create container
az storage container create --name terraform-state --account-name tfstate$(uuidgen | cut -c1-8)
```

After creating these resources, set the corresponding GitHub secrets.

## Further Security Considerations

Consider implementing OIDC authentication for passwordless authentication between GitHub and Azure.

### OIDC Setup

1. Create an Azure AD Application with federated credentials:

```bash
# Create the application
az ad app create --display-name "GitHub-AzureOIDC"

# Get the object ID
objectId=$(az ad app list --display-name "GitHub-AzureOIDC" --query "[0].id" -o tsv)

# Create a service principal
az ad sp create --id $objectId

# Assign Contributor role
spId=$(az ad sp list --display-name "GitHub-AzureOIDC" --query "[0].id" -o tsv)
az role assignment create --assignee $spId \
                       --role Contributor \
                       --scope /subscriptions/{subscription-id}

# Add federated credential for your GitHub repository
az ad app federated-credential create \
  --id $objectId \
  --parameters "{\"name\":\"github-federated\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:your-org/your-repo:ref:refs/heads/main\",\"audiences\":[\"api://AzureADTokenExchange\"]}"
```

2. Update the Azure Login step in your GitHub workflow to use OIDC:

```yaml
- name: Azure Login with OIDC
  uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    # No client secret needed with OIDC!
```

3. Ensure your workflow has the right permissions:

```yaml
permissions:
  id-token: write
  contents: read
```

This provides a more secure authentication method without storing long-lived credentials. 