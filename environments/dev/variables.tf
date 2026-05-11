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

variable "project_name" {
  description = "Project name used for resource names and tags."
  type        = string
  default     = "cloud-desktop"
}

variable "vpc_id" {
  description = "Existing VPC ID."
  type        = string
}

variable "subnet_ids" {
  description = "Existing subnet IDs for cloud desktop placement."
  type        = list(string)
  default     = null
}

variable "private_subnet_ids" {
  description = "Deprecated alias for subnet_ids. Kept for compatibility with the original private-subnet-only example."
  type        = list(string)
  default     = null
}

variable "assign_public_ip" {
  description = "Assign a public IPv4 address to each cloud desktop. Use only with public subnets and tightly scoped SSH ingress."
  type        = bool
  default     = false
}

variable "use_elastic_ip" {
  description = "Allocate and associate an Elastic IP for each cloud desktop. Useful with auto-stop so SSH hostnames remain stable after restart."
  type        = bool
  default     = false
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to cloud desktops."
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

variable "enable_auto_stop" {
  description = "Create CloudWatch alarms that stop cloud desktops after sustained low CPU."
  type        = bool
  default     = false
}

variable "auto_stop_idle_minutes" {
  description = "How many minutes of sustained low CPU should pass before stopping a cloud desktop."
  type        = number
  default     = 60
}

variable "auto_stop_period_seconds" {
  description = "CloudWatch alarm period in seconds for auto-stop CPU checks."
  type        = number
  default     = 300
}

variable "auto_stop_cpu_threshold_percent" {
  description = "Average CPU utilization threshold used by the auto-stop alarm."
  type        = number
  default     = 5
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
