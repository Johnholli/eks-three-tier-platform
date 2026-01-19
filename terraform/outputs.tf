output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "bastion_public_ip" {
  value = aws_eip.bastion.public_ip
}

output "cluster_autoscaler_role_arn" {
  value = module.cluster_autoscaler_irsa.iam_role_arn
}

output "aws_load_balancer_controller_role_arn" {
  value = module.aws_load_balancer_controller_irsa.iam_role_arn
}
