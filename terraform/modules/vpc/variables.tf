variable "name" {
  type = string
}

variable "cidr" {
  type = string
}

variable "azs" {
  type    = list(string)
  default = null
}

variable "az_count" {
  type    = number
  default = 3

  validation {
    condition     = var.az_count > 0
    error_message = "az_count must be greater than 0."
  }
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "one_nat_gateway_per_az" {
  type    = bool
  default = false
}

variable "public_subnet_tags" {
  type    = map(string)
  default = {}
}

variable "private_subnet_tags" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_flow_logs" {
  type    = bool
  default = true
}

variable "flow_logs_traffic_type" {
  type    = string
  default = "ALL"
}

variable "flow_logs_destination_type" {
  type    = string
  default = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_logs_destination_type)
    error_message = "flow_logs_destination_type must be \"cloud-watch-logs\" or \"s3\"."
  }
}

variable "flow_logs_s3_arn" {
  type    = string
  default = null

  validation {
    condition     = var.flow_logs_destination_type != "s3" || (var.flow_logs_s3_arn != null && var.flow_logs_s3_arn != "")
    error_message = "flow_logs_s3_arn must be set when flow_logs_destination_type is \"s3\"."
  }
}

variable "flow_logs_retention_in_days" {
  type    = number
  default = 14
}

variable "flow_logs_kms_key_id" {
  type    = string
  default = null
}
