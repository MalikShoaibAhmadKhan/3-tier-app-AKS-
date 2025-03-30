# Fixing External Connectivity Issues in AKS Cluster

## Problem Description
The cluster was experiencing connectivity issues where external traffic was not properly reaching the services despite having:
- A properly configured Azure Load Balancer
- Correct backend pool registration
- Open Network Security Group (NSG) rules
- Functioning ingress controller

## Root Cause
The issue was related to how the ingress-nginx controller was handling external traffic. By default, the `externalTrafficPolicy` was set to `Cluster`, which:
- Routes traffic through kube-proxy
- Causes an extra network hop
- Can lead to suboptimal routing and potential connectivity issues
- Masks the original client IP address

## Solution
We implemented the following changes to resolve the issue:

1. Modified the ingress-nginx controller service configuration to use `externalTrafficPolicy: Local`:
   ```yaml
   spec:
     type: LoadBalancer
     externalTrafficPolicy: Local
   ```

2. Made the change permanent by adding the configuration to the Helm chart:
   - Created `helm-chart/templates/ingress-nginx-config.yaml` with the service definition
   - Updated `helm-chart/values.yaml` to include:
     ```yaml
     ingressNginx:
       enabled: true
       controller:
         service:
           externalTrafficPolicy: Local
     ```

## Benefits of the Solution
Setting `externalTrafficPolicy: Local`:
- Preserves client source IPs
- Eliminates extra network hops
- Routes traffic directly to the pod on the node that receives it
- Improves overall performance and reliability

## Verification
After implementing the changes, we confirmed that:
1. The frontend UI is accessible at `http://<EXTERNAL-IP>/frontend/`
2. Service A's API is reachable at `http://<EXTERNAL-IP>/api/service-a/data`
3. Service B's API is reachable at `http://<EXTERNAL-IP>/api/service-b/data`

## Infrastructure Configuration
The solution works in conjunction with:
- Azure Load Balancer configured with proper health probes
- NSG rules allowing inbound traffic on ports 80, 443, and 30000-32767
- Kubernetes services properly configured with correct selectors and ports

## Maintaining the Solution
To ensure the configuration persists:
1. Keep the ingress-nginx configuration in the Helm chart
2. Apply any future changes through Helm upgrades
3. Monitor the ingress controller's logs for any potential issues
4. Ensure NSG rules remain properly configured when making network changes 