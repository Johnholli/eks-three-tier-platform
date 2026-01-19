data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  flow_logs_to_cw = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs"
  flow_logs_to_s3 = var.enable_flow_logs && var.flow_logs_destination_type == "s3"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21.0"

  name = var.name
  cidr = var.cidr

  azs             = var.azs != null ? var.azs : slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags  = var.public_subnet_tags
  private_subnet_tags = var.private_subnet_tags

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = local.flow_logs_to_cw ? 1 : 0
  name              = "/vpc-flow-logs/${var.name}"
  retention_in_days = var.flow_logs_retention_in_days
  kms_key_id        = var.flow_logs_kms_key_id
  tags              = var.tags
}

resource "aws_iam_role" "flow_logs" {
  count = local.flow_logs_to_cw ? 1 : 0
  name  = "${var.name}-flow-logs"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = local.flow_logs_to_cw ? 1 : 0
  name  = "${var.name}-flow-logs"
  role  = aws_iam_role.flow_logs[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
    }]
  })
}

resource "aws_flow_log" "vpc" {
  count                = var.enable_flow_logs ? 1 : 0
  vpc_id               = module.vpc.vpc_id
  traffic_type         = var.flow_logs_traffic_type
  log_destination_type = var.flow_logs_destination_type
  log_destination      = local.flow_logs_to_cw ? aws_cloudwatch_log_group.flow_logs[0].arn : var.flow_logs_s3_arn
  iam_role_arn         = local.flow_logs_to_cw ? aws_iam_role.flow_logs[0].arn : null
  tags                 = var.tags
}
