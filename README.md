# Kubernetes Microservices Demo

This repository demonstrates a simple microservices architecture deployed with Kubernetes. It includes:

- A frontend service
- Two backend microservices (service-a and service-b)
- PostgreSQL database
- Kubernetes deployment configurations

## Architecture

- **Frontend**: Simple web interface that communicates with the backend services
- **Service A**: Primary backend service with database access
- **Service B**: Secondary backend service
- **Database**: PostgreSQL instance for data persistence

## Local Development

Use Docker Compose for local development:

```bash
docker-compose up
```

This will start all services including:
- Frontend on port 8080
- Service A on port 3001
- Service B on port 3002
- PostgreSQL on port 5432

## Kubernetes Deployment

### Prerequisites

- Kubernetes cluster (Minikube, kind, or a cloud provider)
- kubectl configured to access your cluster

### Sensitive Data

Before deploying, you need to set up the database secrets:

1. Copy the template file:
   ```bash
   cp kubernetes/db-secret.example.yaml kubernetes/db-secret.yaml
   ```

2. Edit `kubernetes/db-secret.yaml` and replace placeholders with your base64-encoded credentials:
   ```bash
   echo -n "your_username" | base64
   echo -n "your_password" | base64
   echo -n "your_dbname" | base64
   ```

### Deploying

Apply the Kubernetes manifests:

```bash
kubectl apply -f kubernetes/db-secret.yaml
kubectl apply -f kubernetes/db-pvc.yaml
kubectl apply -f kubernetes/db-deployment-service.yaml
kubectl apply -f kubernetes/service-a-deployment-service.yaml
kubectl apply -f kubernetes/service-b-deployment-service.yaml
kubectl apply -f kubernetes/frontend-deployment-service.yaml
```

For more detailed deployment instructions, see [kubernetes/deployment-cycle.md](kubernetes/deployment-cycle.md)

## License

MIT 