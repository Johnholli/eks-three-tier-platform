module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.14.0"

  name               = local.cluster_name
  kubernetes_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Cluster endpoint access
  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = [format("%s/32", aws_eip.bastion.public_ip)]

  security_group_additional_rules = {
    bastion_https = {
      description              = "Allow bastion access to the EKS API"
      type                     = "ingress"
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      source_security_group_id = aws_security_group.bastion.id
    }
  }

  # REQUIRED in v21
  enable_irsa = true
  enable_cluster_creator_admin_permissions = true

  # Addons (do NOT pin versions yet)
  addons = {
    vpc-cni = {
      before_compute = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"

      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
    coredns = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    kube-proxy = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  access_entries = {
    bastion = {
      principal_arn = aws_iam_role.bastion.arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # Managed Node Group
  eks_managed_node_groups = {
    default = {
      name = "ng-default"

      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 2
      desired_size = 2

      # IMPORTANT:
      # Let v21 choose AL2023 automatically
      # Do NOT set ami_type

      disk_size = 20

      tags = {
        "k8s.io/cluster-autoscaler/enabled"                = "true"
        "k8s.io/cluster-autoscaler/${local.cluster_name}"  = "owned"
      }

      subnet_ids = module.vpc.private_subnets
    }
  }

  tags = local.tags
}

module "vpc_cni_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name_prefix = "${local.cluster_name}-vpc-cni"

  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}
