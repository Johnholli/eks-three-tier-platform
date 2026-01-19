# EKS Three-Tier Platform

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.29-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-v3-0F1689?logo=helm&logoColor=white)](https://helm.sh/)

This repo provisions an EKS cluster with a VPC (public/private subnets, NAT, flow logs), a bastion for access, and a three-tier demo app (frontend, backend, MongoDB) deployed via Kubernetes manifests.

## Architecture
```mermaid
flowchart LR
User[User/Browser] --> ALB[ALB Ingress]
ALB --> FE[Frontend Pod]
ALB -->|/api| BE[Backend Pod]
BE --> DB[MongoDB Pod]
Bastion[Bastion SSM] --> EKS[EKS Cluster]
```

## Screenshots
<img src="docs/screenshots/app-ui.png" alt="App UI" width="900" />

<img src="https://github.com/user-attachments/assets/d49bce40-e49a-4681-85a2-ed27f3c3b020" />

<img src="https://github.com/user-attachments/assets/a1e9f4e2-42bf-4b3c-b7fd-844ba54c5eda" />

<img src="https://github.com/user-attachments/assets/153b6b0b-fecc-43c4-a9c3-76efd7f5412d" />

## Repo Layout
- terraform/: core infrastructure (VPC, EKS, bastion, IRSA roles)
- terraform/three-tier-eks-iac/: app source + manifests + updated README

## Project Highlights
- Built a complete three-tier app platform on EKS using Terraform
- Secured access with a bastion and least-privilege IAM roles (IRSA)
- Automated scaling and ingress with Kubernetes controllers
- Verified end-to-end app + API + database connectivity

## Prerequisites
- Terraform >= 1.5
- AWS CLI v2
- kubectl
- Helm

## Deploy
1) Provision infra
```
cd terraform
terraform init
terraform apply
```

2) Access the cluster
If the EKS API is locked to the bastion EIP, run kubectl/helm from the bastion (SSM session).

3) Deploy the app
```
cd terraform/three-tier-eks-iac
kubectl create ns workshop
kubectl config set-context --current --namespace workshop

kubectl apply -f k8s_manifests/mongo/secrets.yaml
kubectl apply -f k8s_manifests/mongo/deploy.yaml
kubectl apply -f k8s_manifests/mongo/service.yaml
kubectl apply -f k8s_manifests/backend-deployment.yaml
kubectl apply -f k8s_manifests/backend-service.yaml
kubectl apply -f k8s_manifests/frontend-deployment.yaml
kubectl apply -f k8s_manifests/frontend-service.yaml
kubectl apply -f k8s_manifests/full_stack_lb.yaml
```

## Runbook
### Verify
```
kubectl get nodes
kubectl get pods -n workshop
kubectl get ingress -n workshop
```

If the ingress address is present, test through the ALB:
```
ALB_DNS=$(kubectl get ingress -n workshop mainlb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -H "Host: app.sandipdas.in" http://${ALB_DNS}
curl -H "Host: app.sandipdas.in" http://${ALB_DNS}/api/tasks
curl -H "Host: app.sandipdas.in" -H "Content-Type: application/json" -X POST -d '{"task":"test task"}' http://${ALB_DNS}/api/tasks
```

### Logs
```
kubectl logs -n kube-system deployment/aws-load-balancer-controller -f
kubectl logs -n kube-system deployment/cluster-autoscaler-aws-cluster-autoscaler -f
```

### Destroy
```
cd terraform
terraform destroy
```

## Destroy Checklist
1) Delete app resources
```
kubectl delete -f k8s_manifests/full_stack_lb.yaml
kubectl delete -f k8s_manifests/frontend-deployment.yaml
kubectl delete -f k8s_manifests/frontend-service.yaml
kubectl delete -f k8s_manifests/backend-deployment.yaml
kubectl delete -f k8s_manifests/backend-service.yaml
kubectl delete -f k8s_manifests/mongo/deploy.yaml
kubectl delete -f k8s_manifests/mongo/service.yaml
kubectl delete -f k8s_manifests/mongo/secrets.yaml
```

2) Remove Helm installs (optional)
```
helm uninstall aws-load-balancer-controller -n kube-system
helm uninstall cluster-autoscaler -n kube-system
helm uninstall cert-manager -n cert-manager
```

3) Destroy infra
```
cd terraform
terraform destroy
```
