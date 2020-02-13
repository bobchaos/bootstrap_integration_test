output "bastion_public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "The bastion's public IP address"
}

output "omnibus_private_ip" {
  value       = aws_instance.omnibus.private_ip
  description = "Private IP of the instance building Chef Infra"
}

output "server_private_dns" {
  value       = aws_instance.chef-server.private_dns
  description = "Private IP of the Chef Infra Server"
}

output "nix_nodes" {
  value       = local.nix_nodes
  description = "An array of private IPs belonging to Unix-like systems to bootstrap to Chef"
}

output "win_nodes" {
  value       = local.win_nodes
  description = "An array of private IPs belonging to Windows systems to bootstrap to Chef"
}
