output "ai_server_remote_address" {
  description = "SSH connection string for the ai host (user@ip)."
  //value       = module.ec2.ai_server_remote_address
  value = { for name, instance in module.ec2 : name => instance.ai_server_remote_address }
}

output "bastion_remote_address" {
  description = "SSH connection string for the bastion host (user@ip)."
  value       = module.bastion.jumpserver_remote_address
}
