# GitOps Deployment with ArgoCD on Azure Kubernetes Service (AKS)

👋 Welcome! This repository demonstrates a complete GitOps deployment pipeline using ArgoCD on Azure Kubernetes Service (AKS).

## 📚 Documentation Overview

1.  [Prerequisites](#-prerequisites) - What you need before starting.
2.  [Setup (One-Time Manual Steps)](#-setup-one-time-manual-steps) - Creating credentials and backend storage.
3.  [Configure GitHub Secrets](#-configure-github-secrets) - Adding credentials to your repository.
4.  [Automated Deployment (CI/CD)](#-automated-deployment-cicd) - Running the main deployment workflow.
5.  [Accessing the Application](#-accessing-the-application) - Getting your application URLs.
6.  [Architecture](#-architecture-overview)
7.  [Troubleshooting](#-quick-troubleshooting-guide)
8.  [Cleanup](#-cleanup)
9.  [Manual Deployment (Optional)](#-manual-deployment-guide-optional)
10. [Other Sections](#-other-sections) (How GitOps Works, Secret Management, etc.)

---

## ✅ Prerequisites

Before you begin, ensure you have:

*   **Azure Account:** An active Azure Subscription ([Get a free account](https://azure.microsoft.com/free/)).
*   **GitHub Account:** To fork and manage the repository.
*   **Forked Repository:** Fork this repository `https://github.com/wahaj4311/3-tier-app.git` to your GitHub account.
*   **Required Tools Installed:**
    *   [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli): `az --version`
    *   [kubectl](https://kubernetes.io/docs/tasks/tools/): `kubectl version --client`
    *   [Terraform](https://www.terraform.io/downloads.html): `terraform --version`
    *   [jq](https://stedolan.github.io/jq/download/): (For easy credential extraction) `jq --version`
    *   [GitHub CLI](https://cli.github.com/) (Optional, for triggering workflows): `gh --version`

---

## ⚙️ Setup (One-Time Manual Steps)

These steps create the necessary Azure credentials and the remote backend storage for Terraform. **This only needs to be done once per setup.**

```bash
# --- Step 1: Login to Azure CLI ---
az login

# --- Step 2: Create Azure Service Principal ---
# Replace <your-subscription-id> with your actual Azure Subscription ID.
# This command creates credentials for GitHub Actions to interact with Azure.
# The output (JSON) is saved to 'sp_output.json'. Keep this file safe.
echo "Creating Azure Service Principal..."
az ad sp create-for-rbac --name "kubemicrodemo-sp-$(date +%s)" \
  --role contributor \
  --scopes /subscriptions/<your-subscription-id> \
  --sdk-auth > sp_output.json

if [ $? -ne 0 ]; then
  echo "Error creating Service Principal. Please check Azure permissions and subscription ID."
  exit 1
fi
echo "Service Principal created. Credentials saved to sp_output.json"

# --- Step 3: Create Terraform Backend Storage ---
# This uses Terraform locally (with the SP created above) to create the
# Azure Storage Account and Container where the main infrastructure state will live.
echo "Creating Terraform backend storage..."
cd terraform/bootstrap

# Initialize Terraform (uses local state for this bootstrap step)
terraform init -reconfigure

# Plan and Apply to create the storage resources.
# It uses the Service Principal credentials from sp_output.json.
export ARM_CLIENT_ID=$(cat ../../sp_output.json | jq -r .clientId)
export ARM_CLIENT_SECRET=$(cat ../../sp_output.json | jq -r .clientSecret)
export ARM_TENANT_ID=$(cat ../../sp_output.json | jq -r .tenantId)
export ARM_SUBSCRIPTION_ID=<your-subscription-id> # Replace with your Subscription ID

# You can also pass variables directly if preferred:
# TF_VAR_client_id=$ARM_CLIENT_ID TF_VAR_client_secret=$ARM_CLIENT_SECRET ... terraform plan/apply

terraform plan -out=bootstrap.tfplan \
  -var="client_id=$ARM_CLIENT_ID" \
  -var="client_secret=$ARM_CLIENT_SECRET" \
  -var="tenant_id=$ARM_TENANT_ID" \
  -var="subscription_id=$ARM_SUBSCRIPTION_ID" \
  -var="location=eastus" # Optional: Change location if needed

if [ $? -ne 0 ]; then
  echo "Error planning Terraform bootstrap. Check variables and SP permissions."
  cd ../..
  exit 1
fi

terraform apply -auto-approve bootstrap.tfplan

# --- Handling Potential Naming Conflicts ---
# The bootstrap code attempts to create a storage account named 'tfstatekubemicro'.
# Storage account names must be globally unique in Azure. If the previous command
# failed due to a naming conflict (e.g., "StorageAccountAlreadyTaken"), 
# you need to manually choose a unique name:
#   1. Edit the file: terraform/bootstrap/main.tf
#   2. Find the 'azurerm_storage_account' resource block.
#   3. Change the 'name' argument from "tfstatekubemicro" to a unique name 
#      (e.g., "tfstate<yourinitials><date>").
#   4. Re-run 'terraform plan -out=bootstrap.tfplan ...' and 'terraform apply bootstrap.tfplan' above.
#   5. IMPORTANT: Remember the unique name you used! You'll need it for the GitHub secret.

if [ $? -ne 0 ]; then
  echo "Error applying Terraform bootstrap. Check Azure status, permissions, or potential naming conflicts."
  cd ../..
  exit 1
fi

echo "Terraform backend storage created successfully."

# --- Step 4: Navigate back and cleanup (optional) ---
cd ../..
# Consider deleting sp_output.json after adding secrets to GitHub, or store it securely.
# echo "Setup complete. Remember to add the required secrets to your GitHub repository."
# rm sp_output.json
```

---

## 🔒 Configure GitHub Secrets

After completing the one-time setup, go to your forked repository on GitHub -> Settings -> Secrets and variables -> Actions -> "New repository secret" and add the following:

*   **Credentials from Service Principal (`sp_output.json`):**
    *   `AZURE_CLIENT_ID`: (Value of `clientId` from `sp_output.json`)
    *   `AZURE_CLIENT_SECRET`: (Value of `clientSecret` from `sp_output.json`)
    *   `AZURE_TENANT_ID`: (Value of `tenantId` from `sp_output.json`)
    *   `AZURE_SUBSCRIPTION_ID`: Your Azure Subscription ID.
*   **Terraform Backend Details (Resource Group & Container are fixed):**
    *   `TERRAFORM_STORAGE_RG`: `kubemicrodemo-terraform-storage-rg`
    *   `TERRAFORM_STORAGE_ACCOUNT`: `tfstatekubemicro` **(or the unique name you chose if the default was taken)**
    *   `TERRAFORM_CONTAINER`: `tfstate`
*   **Application Secrets:**
    *   `DB_USERNAME`: Desired username for the application database (e.g., `postgresadmin`).
    *   `DB_PASSWORD`: Desired **strong** password for the application database.
*   **Optional AKS Naming (Defaults are used if not set):**
    *   `AKS_RESOURCE_GROUP`: (Default: `aks-gitops-rg`)
    *   `AKS_CLUSTER_NAME`: (Default: `aks-gitops-cluster`)

**Important:** Ensure these secrets are added accurately before proceeding.

---

## ▶️ Automated Deployment (CI/CD)

With prerequisites met and secrets configured, the deployment is fully automated via GitHub Actions.

**What the Workflow Does:**

1.  **Build & Push:** Builds application Docker images and pushes them to GitHub Container Registry.
2.  **Terraform Apply (Main):** Connects to the Azure Terraform backend (created during setup) and uses the main Terraform configuration (`terraform/`) to provision/update Azure infrastructure (AKS Cluster, Key Vault, etc.).
3.  **ArgoCD & Tools Installation:** Installs ArgoCD, NGINX Ingress Controller, and Azure Key Vault CSI driver onto the AKS cluster.
4.  **Application Deployment:** Configures ArgoCD applications to deploy your microservices using the Helm chart.

**Trigger the Workflow:**

*   **Option 1: GitHub UI**
    1.  Go to the "Actions" tab in your forked repository.
    2.  Select the "**Deploy ArgoCD Applications**" workflow (or potentially "**Deploy to AKS**" depending on which one orchestrates the full process). *Please verify the correct workflow name.*
    3.  Click "Run workflow", choose the environment (e.g., `all` or `prod`), ensure the action is `deploy`, and click "Run workflow".
*   **Option 2: GitHub CLI** (Ensure you target the correct workflow name)
    ```bash
    # Verify workflow name first using: gh workflow list
    gh workflow run "Deploy ArgoCD Applications" -f environment=all -f action=deploy
    ```

Monitor the workflow progress in the Actions tab. It might take 15-30 minutes for the first run.

---

## 🌐 Accessing the Application

After the workflow completes successfully (allow a few minutes for IPs to be assigned):

1.  **Application Services:**
    ```bash
    # Get the Ingress Controller's external IP
    INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    while [ -z "$INGRESS_IP" ]; do echo "Waiting for Ingress IP..."; sleep 10; INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'); done

    # Access URLs
    echo "-------------------------------------"
    echo "Application URLs:"
    echo "Frontend UI: http://$INGRESS_IP/frontend/"
    echo "Service A API: http://$INGRESS_IP/api/service-a/"
    echo "Service B API: http://$INGRESS_IP/api/service-b/"
    echo "-------------------------------------"
    ```

2.  **ArgoCD Dashboard:**
    ```bash
    # Get ArgoCD server external IP
    ARGOCD_IP=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    while [ -z "$ARGOCD_IP" ]; do echo "Waiting for ArgoCD IP..."; sleep 10; ARGOCD_IP=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}'); done

    # Get initial admin password
    ARGO_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

    echo "-------------------------------------"
    echo "ArgoCD Dashboard:"
    echo "URL: https://$ARGOCD_IP"
    echo "Username: admin"
    echo "Password: $ARGO_PASS"
    echo "-------------------------------------"
    ```
    *Alternatively, use port forwarding:* `kubectl port-forward svc/argocd-server -n argocd 8080:443` *(Access at `https://localhost:8080`)*

---

## 🏗️ Architecture Overview

*(Existing diagram and text)*
![Architecture Diagram](architecture.png)
...

---

## 🔍 Quick Troubleshooting Guide

*(Existing Troubleshooting Section)*
If the application is not accessible...

---

## 🧹 Cleanup

*(Existing Cleanup Section)*
To remove all resources...

---

## 📜 Manual Deployment Guide (Optional)

*(Existing Manual Deployment Section)*
Follow these steps to deploy the application manually...

---

## <a name="other-sections"></a> Other Sections

*(Existing sections like How GitOps Works, Secret Management, Learning Outcomes, etc.)*
...