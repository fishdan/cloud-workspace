output "instance_ids" {
  description = "EC2 instance IDs by engineer key."
  value       = module.devbox.instance_ids
}

output "private_ips" {
  description = "Private IPv4 addresses by engineer key."
  value       = module.devbox.private_ips
}

output "workspace_volume_ids" {
  description = "Persistent workspace EBS volume IDs by engineer key."
  value       = module.devbox.workspace_volume_ids
}

output "ssh_config" {
  description = "Suggested SSH config snippets by engineer key."
  value       = module.devbox.ssh_config
}
