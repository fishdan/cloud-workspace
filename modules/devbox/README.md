# devbox Module

Creates private Ubuntu developer workstations for a map of engineers.

## Interface

Required inputs:

- `environment`
- `cost_center`
- `vpc_id`
- `private_subnet_ids`
- `engineers`

Optional inputs:

- `ami_id` to pin a specific Ubuntu AMI. When unset, the module discovers the latest Ubuntu 24.04 LTS amd64 gp3 AMI from Canonical.
- `allowed_ssh_cidr_blocks` to restrict SSH. When unset, the VPC CIDR is used.
- `default_instance_type`
- `default_workspace_size_gb`
- `root_volume_size_gb`
- `tags`

Each engineer supports:

- `username`
- `ssh_public_key`
- `instance_type`
- `workspace_size_gb`
- `enabled`
- `subnet_index`
- `tags`

Workspace volumes use `prevent_destroy = true`.
