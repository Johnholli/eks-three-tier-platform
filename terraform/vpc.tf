module "vpc" {
  source = "./modules/vpc"

  name = "${local.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  az_count = 3

  # Public subnets: for ALB/NLB + NAT Gateway
  public_subnets = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]

  # Private subnets: for EKS nodes/pods (recommended)
  private_subnets = ["10.0.128.0/20", "10.0.144.0/20", "10.0.160.0/20"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_flow_logs             = true
  flow_logs_destination_type   = "cloud-watch-logs"
  flow_logs_retention_in_days  = 14

  # EKS discovers subnets using these tags:
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  # Cluster tag: lets EKS + LB controller identify shared subnets
  tags = merge(local.tags, {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  })
}
