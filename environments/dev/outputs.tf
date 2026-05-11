output "instance_ids" {
  description = "EC2 instance IDs by engineer key."
  value       = module.devbox.instance_ids
}

output "private_ips" {
  description = "Private IPv4 addresses by engineer key."
  value       = module.devbox.private_ips
}

output "public_ips" {
  description = "Public IPv4 addresses by engineer key. Values are empty when assign_public_ip is false."
  value       = module.devbox.public_ips
}

output "elastic_ip_allocation_ids" {
  description = "Elastic IP allocation IDs by engineer key. Empty unless use_elastic_ip is true."
  value       = module.devbox.elastic_ip_allocation_ids
}

output "workspace_volume_ids" {
  description = "Persistent workspace EBS volume IDs by engineer key."
  value       = module.devbox.workspace_volume_ids
}

output "ssh_config" {
  description = "Suggested SSH config snippets by engineer key."
  value       = module.devbox.ssh_config
}

output "tailscale_ssh_config" {
  description = "Suggested SSH config snippets using Tailscale MagicDNS hostnames."
  value       = module.devbox.tailscale_ssh_config
}
