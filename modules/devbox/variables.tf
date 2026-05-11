variable "environment" {
  description = "Environment name used for naming and tags."
  type        = string
}

variable "cost_center" {
  description = "Cost center tag applied to all resources."
  type        = string
}

variable "project_name" {
  description = "Project name used for resource names and tags."
  type        = string
  default     = "cloud-desktop"
}

variable "vpc_id" {
  description = "ID of the VPC where cloud desktops run."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for cloud desktop placement. Use public subnets when assign_public_ip is true, or private subnets with egress when false."
  type        = list(string)
  default     = null
}

variable "private_subnet_ids" {
  description = "Deprecated alias for subnet_ids. Kept for compatibility with the original private-subnet-only module interface."
  type        = list(string)
  default     = null
}

variable "assign_public_ip" {
  description = "Assign a public IPv4 address to each cloud desktop. Use only with public subnets and tightly scoped SSH ingress."
  type        = bool
  default     = false
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
  default     = "t3.small"
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

variable "tailscale_auth_key" {
  description = "Optional Tailscale auth key used to join each cloud desktop to a tailnet. When null, Tailscale is not installed."
  type        = string
  default     = null
  sensitive   = true
}

variable "tailscale_enable_ssh" {
  description = "Enable Tailscale SSH on joined cloud desktops. Normal OpenSSH remains configured either way."
  type        = bool
  default     = false
}

variable "tailscale_accept_routes" {
  description = "Accept routes advertised by other Tailscale subnet routers."
  type        = bool
  default     = false
}

variable "engineers" {
  description = "Per-engineer cloud desktop configuration."
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
