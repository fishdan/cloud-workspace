module "devbox" {
  source = "../../modules/devbox"

  environment                     = var.environment
  cost_center                     = var.cost_center
  project_name                    = var.project_name
  vpc_id                          = var.vpc_id
  subnet_ids                      = var.subnet_ids
  private_subnet_ids              = var.private_subnet_ids
  assign_public_ip                = var.assign_public_ip
  use_elastic_ip                  = var.use_elastic_ip
  allowed_ssh_cidr_blocks         = var.allowed_ssh_cidr_blocks
  ami_id                          = var.ami_id
  default_instance_type           = var.default_instance_type
  default_workspace_size_gb       = var.default_workspace_size_gb
  root_volume_size_gb             = var.root_volume_size_gb
  tailscale_auth_key              = var.tailscale_auth_key
  tailscale_enable_ssh            = var.tailscale_enable_ssh
  tailscale_accept_routes         = var.tailscale_accept_routes
  enable_auto_stop                = var.enable_auto_stop
  auto_stop_idle_minutes          = var.auto_stop_idle_minutes
  auto_stop_period_seconds        = var.auto_stop_period_seconds
  auto_stop_cpu_threshold_percent = var.auto_stop_cpu_threshold_percent
  engineers                       = var.engineers
  tags                            = var.tags
}
