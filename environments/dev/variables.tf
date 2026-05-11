variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "cost_center" {
  description = "Cost center tag applied to all resources."
  type        = string
}

variable "vpc_id" {
  description = "Existing VPC ID."
  type        = string
}

variable "private_subnet_ids" {
  description = "Existing private subnet IDs."
  type        = list(string)
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to dev boxes."
  type        = list(string)
  default     = null
}

variable "engineers" {
  description = "Per-engineer dev box configuration."
  type = map(object({
    username          = string
    ssh_public_key    = string
    instance_type     = optional(string)
    workspace_size_gb = optional(number)
    enabled           = optional(bool, true)
    subnet_index      = optional(number, 0)
    tags              = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
