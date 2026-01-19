variable "bastion_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "bastion_volume_size" {
  type    = number
  default = 30

  validation {
    condition     = var.bastion_volume_size >= 30
    error_message = "bastion_volume_size must be at least 30 GB to match the AL2023 AMI snapshot size."
  }
}
