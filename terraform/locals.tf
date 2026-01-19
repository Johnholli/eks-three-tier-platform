locals {
  cluster_name = "my-eks-cluster"

  tags = {
    Project     = "eks-three-tier-app"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}
