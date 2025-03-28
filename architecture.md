# GitOps Architecture with ArgoCD on AKS

```
┌─────────────────┐        ┌──────────────┐        ┌─────────────────┐
│                 │        │              │        │                 │
│  GitHub Repo    │◄──────►│  GitHub      │        │  Azure          │
│  (Source of     │        │  Actions     │        │  Resources      │
│   Truth)        │        │  Workflow    │        │                 │
│                 │        │              │        │                 │
└────────┬────────┘        └──────┬───────┘        └─────────────────┘
         │                        │                        ▲
         │                        │                        │
         │                        ▼                        │
         │               ┌──────────────┐                  │
         │               │              │                  │
         │               │  Container   │                  │
         │               │  Registry    │                  │
         │               │              │                  │
         │               └──────┬───────┘                  │
         │                      │                          │
         │                      │                          │
         ▼                      ▼                          │
┌─────────────────┐    ┌──────────────────────────────────┼───┐
│                 │    │                                   │   │
│                 │    │  Azure Kubernetes Service (AKS)   │   │
│  ArgoCD         │    │                                   │   │
│  (Monitoring    │    │  ┌───────────┐    ┌────────────┐  │   │
│   Changes)      │◄───┼──┤ ArgoCD    ├────► Application │  │   │
│                 │    │  │ Controller│    │ Workloads   │  │   │
│                 │    │  └───────────┘    └──────┬─────┘  │   │
└─────────────────┘    │                         ▲         │   │
                       │                         │         │   │
                       │  ┌───────────┐    ┌────┴─────┐   │   │
                       │  │ Azure Key │    │ CSI      │   │   │
                       │  │ Vault     ├────► Driver   │   │   │
                       │  └───────────┘    └──────────┘   │   │
                       │                                   │   │
                       └───────────────────────────────────────┘
```

## GitOps Workflow Explanation

1. **Source of Truth**: Developers commit application code and Kubernetes manifests to GitHub
   
2. **CI Pipeline**: GitHub Actions builds container images and pushes them to the registry

3. **Infrastructure Provisioning**: Terraform creates and manages Azure resources (AKS, Key Vault)

4. **GitOps Controller**: ArgoCD continuously monitors the Git repository for changes

5. **Automated Deployment**: When changes are detected, ArgoCD automatically applies them to the cluster

6. **Secret Management**: Azure Key Vault securely stores secrets, which are accessed by the application via the CSI Driver

7. **Observability**: ArgoCD provides visibility into sync status and deployment health 