# devbox Module

Creates Ubuntu cloud desktops for a map of engineers.

## Interface

Required inputs:

- `environment`
- `cost_center`
- `vpc_id`
- `engineers`

Optional inputs:

- `project_name` for resource names and the `Project` tag. Defaults to `cloud-desktop`.
- `subnet_ids` for cloud desktop placement. Use public subnets when `assign_public_ip` is `true`, or private subnets with egress when `false`.
- `private_subnet_ids` as a deprecated compatibility alias for `subnet_ids`.
- `assign_public_ip` to assign public IPv4 addresses to instances. Defaults to `false`.
- `use_elastic_ip` to allocate and associate stable Elastic IP addresses. Defaults to `false`.
- `ami_id` to pin a specific Ubuntu AMI. When unset, the module discovers the latest Ubuntu 24.04 LTS amd64 gp3 AMI from Canonical.
- `allowed_ssh_cidr_blocks` to restrict SSH. When unset, the VPC CIDR is used.
- `default_instance_type`
- `default_workspace_size_gb`
- `root_volume_size_gb`
- `tailscale_auth_key` to install Tailscale and join each cloud desktop to a tailnet. Defaults to `null`.
- `tailscale_enable_ssh` to enable Tailscale SSH after joining the tailnet. Defaults to `false`.
- `tailscale_accept_routes` to accept routes advertised by other Tailscale subnet routers. Defaults to `false`.
- `enable_auto_stop` to create CloudWatch low-CPU stop alarms. Defaults to `false`.
- `auto_stop_idle_minutes`
- `auto_stop_period_seconds`
- `auto_stop_cpu_threshold_percent`
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
