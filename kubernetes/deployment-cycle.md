# Kubernetes Deployment Cycle for Microservice App

This document outlines the typical workflow for deploying updates to the 3-tier microservice application (frontend, service-a, service-b, database) running on Kubernetes.

## Prerequisites

*   Access to a Kubernetes cluster (e.g., Minikube, kind, GKE, EKS, AKS).
*   `kubectl` configured to interact with your cluster.
*   Docker installed locally for building images.
*   Access to a container registry (e.g., Docker Hub, GCR, ECR, ACR) where your Kubernetes cluster can pull images.

## Deployment Workflow

1.  **Code Changes:**
    *   Make necessary modifications to the source code of the relevant service (`frontend`, `service-a`, or `service-b`).
    *   Commit your changes to your version control system (e.g., Git).

2.  **Build Docker Image:**
    *   Navigate to the root directory of the service you modified (e.g., `microservice-app/service-a`).
    *   Build a new Docker image, tagging it appropriately (e.g., with a version number or Git commit hash). Replace `your-repo` with your actual registry username/project.
        ```bash
        # Example for service-a
        docker build -t your-repo/service-a:v1.1 .
        # Or use a commit hash
        # docker build -t your-repo/service-a:$(git rev-parse --short HEAD) .
        ```

3.  **Push Docker Image to Registry:**
    *   Push the newly built image to your container registry.
        ```bash
        # Example for service-a
        docker push your-repo/service-a:v1.1
        ```

4.  **Update Kubernetes Manifest:**
    *   Open the corresponding Kubernetes Deployment YAML file for the service you updated (e.g., `microservice-app/kubernetes/service-a-deployment-service.yaml`).
    *   Find the `spec.template.spec.containers[0].image` field.
    *   Update the image tag to match the new version you just pushed.
        ```yaml
        # Example change in service-a-deployment-service.yaml
        spec:
          template:
            spec:
              containers:
              - name: service-a
                # Update this line
                image: your-repo/service-a:v1.1 # Changed from :latest or previous version
        ```
    *   Commit this change to version control.

5.  **Apply Changes to Kubernetes:**
    *   Navigate to the `microservice-app/kubernetes` directory.
    *   Apply the updated manifest file (or all files if you prefer). Kubernetes will perform a rolling update by default for Deployments.
        ```bash
        # Apply only the changed file
        kubectl apply -f service-a-deployment-service.yaml

        # Or apply all files in the directory
        # kubectl apply -f .
        ```

6.  **Verify Deployment:**
    *   Check the status of the rolling update:
        ```bash
        kubectl rollout status deployment/<deployment-name>
        # Example: kubectl rollout status deployment/service-a-deployment
        ```
    *   Check the Pods to ensure the new version is running:
        ```bash
        kubectl get pods -l app=<app-label>
        # Example: kubectl get pods -l app=service-a
        ```
    *   Check logs if necessary:
        ```bash
        kubectl logs -l app=<app-label>
        # Example: kubectl logs -l app=service-a
        ```
    *   Test the application functionality through the frontend service endpoint.

## Initial Deployment

For the very first deployment:

1.  Ensure all prerequisites are met.
2.  Build and push images for **all** services (`frontend`, `service-a`, `service-b`) tagged appropriately (e.g., `:v1.0`).
3.  Update the `image` fields in all deployment YAML files (`*-deployment-service.yaml`) to point to your pushed images.
4.  Navigate to `microservice-app/kubernetes`.
5.  Apply all the manifest files in the correct order (or let Kubernetes handle dependencies if possible, though applying individually can be clearer initially):
    ```bash
    kubectl apply -f db-secret.yaml
    kubectl apply -f db-pvc.yaml
    kubectl apply -f db-deployment-service.yaml
    kubectl apply -f service-a-deployment-service.yaml
    kubectl apply -f service-b-deployment-service.yaml
    kubectl apply -f frontend-deployment-service.yaml

    # Alternatively, apply all at once:
    # kubectl apply -f .
    ```
6.  Verify the deployment as described in step 6 above. Find the frontend service's NodePort or LoadBalancer IP to access the application.

This cycle forms the basis of CI/CD (Continuous Integration/Continuous Deployment) where steps 2-6 can be automated using tools like Jenkins, GitLab CI, GitHub Actions, etc.
