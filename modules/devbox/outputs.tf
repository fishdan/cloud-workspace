output "instance_ids" {
  description = "EC2 instance IDs by engineer key."
  value       = { for key, instance in aws_instance.devbox : key => instance.id }
}

output "private_ips" {
  description = "Private IPv4 addresses by engineer key."
  value       = { for key, instance in aws_instance.devbox : key => instance.private_ip }
}

output "workspace_volume_ids" {
  description = "Persistent workspace EBS volume IDs by engineer key."
  value       = { for key, volume in aws_ebs_volume.workspace : key => volume.id }
}

output "ssh_config" {
  description = "Suggested SSH config snippets by engineer key."
  value = {
    for key, instance in aws_instance.devbox : key => <<-EOT
      Host devbox-${key}
        HostName ${instance.private_ip}
        User ${local.enabled_engineers[key].username}
        IdentityFile ~/.ssh/id_ed25519
        IdentitiesOnly yes
    EOT
  }
}
