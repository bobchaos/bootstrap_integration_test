output "bastion_public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "The bastion's public IP address"
}

output "centos_omnibus_private_ip" {
  value       = aws_instance.omnibus.private_ip
  description = "Private IP of the instance building Chef Infra"
}

output "centos_omnibus_instance_id" {
  value = aws_instance.omnibus.instance_id
  description = "ID of the centos omnibus builder node"
}

output "server_private_dns" {
  value       = aws_instance.chef-server.private_dns
  description = "Private IP of the Chef Infra Server"
}

output "chef_server_instance_id" {
  value = aws_instance.chef-server.instance_id
  description = "ID of the Chef Infra Server instance"
}

output "nix_nodes" {
  value       = local.nix_nodes
  description = "An array of private IPs belonging to Unix-like systems to bootstrap to Chef"
}

output "win_nodes" {
  value       = local.win_nodes
  description = "An array of private IPs belonging to Windows systems to bootstrap to Chef"
}

output "omnibus_sg_ids" {
  value = aws_instance.omnibus.vpc_security_group_ids
  description = "ID of the omnibus instances' security group"
}

output "chef_server_sg_ids" {
  value = aws_instance.chef-server.vpc_security_group_ids
  description = "ID of the Chef Infra Server instances security group"
}

output "all_vpc_subnet_cidrs" {
  value = local.all_vpc_subnet_cidrs
  description = "All CIDR blocks used in the VPC"
}
