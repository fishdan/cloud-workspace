module "devbox" {
  source = "../../modules/devbox"

  environment             = var.environment
  cost_center             = var.cost_center
  vpc_id                  = var.vpc_id
  private_subnet_ids      = var.private_subnet_ids
  allowed_ssh_cidr_blocks = var.allowed_ssh_cidr_blocks
  engineers               = var.engineers
  tags                    = var.tags
}
