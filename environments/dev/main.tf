module "devbox" {
  source = "../../modules/devbox"

  environment               = var.environment
  cost_center               = var.cost_center
  project_name              = var.project_name
  vpc_id                    = var.vpc_id
  subnet_ids                = var.subnet_ids
  private_subnet_ids        = var.private_subnet_ids
  assign_public_ip          = var.assign_public_ip
  allowed_ssh_cidr_blocks   = var.allowed_ssh_cidr_blocks
  ami_id                    = var.ami_id
  default_instance_type     = var.default_instance_type
  default_workspace_size_gb = var.default_workspace_size_gb
  root_volume_size_gb       = var.root_volume_size_gb
  tailscale_auth_key        = var.tailscale_auth_key
  tailscale_enable_ssh      = var.tailscale_enable_ssh
  tailscale_accept_routes   = var.tailscale_accept_routes
  engineers                 = var.engineers
  tags                      = var.tags
}
