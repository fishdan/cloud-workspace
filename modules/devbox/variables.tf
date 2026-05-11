variable "environment" {
  description = "Environment name used for naming and tags."
  type        = string
}

variable "cost_center" {
  description = "Cost center tag applied to all resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where dev boxes run."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for dev box placement."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) > 0
    error_message = "At least one private subnet ID is required."
  }
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to reach SSH. Defaults to the VPC CIDR."
  type        = list(string)
  default     = null
}

variable "ami_id" {
  description = "Optional Ubuntu 24.04 AMI ID. When null, the latest Canonical Ubuntu 24.04 amd64 gp3 AMI is used."
  type        = string
  default     = null
}

variable "default_instance_type" {
  description = "Default EC2 instance type for engineers that do not specify one."
  type        = string
  default     = "t3.large"
}

variable "default_workspace_size_gb" {
  description = "Default persistent workspace volume size in GiB."
  type        = number
  default     = 100
}

variable "root_volume_size_gb" {
  description = "Encrypted root volume size in GiB."
  type        = number
  default     = 30
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
