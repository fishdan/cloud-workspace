output "instance_ids" {
  description = "EC2 instance IDs by engineer key."
  value       = { for key, instance in aws_instance.devbox : key => instance.id }
}

output "private_ips" {
  description = "Private IPv4 addresses by engineer key."
  value       = { for key, instance in aws_instance.devbox : key => instance.private_ip }
}

output "public_ips" {
  description = "Public IPv4 addresses by engineer key. Values are empty when assign_public_ip is false."
  value = {
    for key, instance in aws_instance.devbox : key => var.use_elastic_ip ? aws_eip.devbox[key].public_ip : instance.public_ip
  }
}

output "elastic_ip_allocation_ids" {
  description = "Elastic IP allocation IDs by engineer key. Empty unless use_elastic_ip is true."
  value       = { for key, eip in aws_eip.devbox : key => eip.allocation_id }
}

output "workspace_volume_ids" {
  description = "Persistent workspace EBS volume IDs by engineer key."
  value       = { for key, volume in aws_ebs_volume.workspace : key => volume.id }
}

output "ssh_config" {
  description = "Suggested SSH config snippets by engineer key."
  value = {
    for key, instance in aws_instance.devbox : key => <<-EOT
      Host ${local.name_prefix}-${key}
        HostName ${var.use_elastic_ip ? aws_eip.devbox[key].public_ip : (var.assign_public_ip ? instance.public_ip : instance.private_ip)}
        User ${local.enabled_engineers[key].username}
        IdentityFile ~/.ssh/id_ed25519
        IdentitiesOnly yes
    EOT
  }
}

output "tailscale_ssh_config" {
  description = "Suggested SSH config snippets using Tailscale MagicDNS hostnames."
  value       = local.tailscale_ssh_config
}
