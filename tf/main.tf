# Create a personal lab with all sorts of devopsy things
provider "aws" {
  # Credentials expected from ENV or ~/.aws/credentials
  version = "~> 2.0"
  region  = "us-east-1"
}

locals {
  tags          = merge({ Terraform = "true" }, var.tags)
  nix_ami_ids   = [data.aws_ami.nix_os_0.id, data.aws_ami.nix_os_1.id]
  nix_nodes     = [aws_instance.nix_nodes[*].private_ip]
  win_passwords = [for p in aws_instance.win_nodes[*].password_data : rsadecrypt(p, tls_private_key.ephemeral.private_key_pem)]
  win_nodes     = zipmap(aws_instance.win_nodes[*].private_ip, local.win_passwords)
  all_vpc_subnet_cidrs = concat(module.main_vpc.private_subnets_cidr_blocks, module.main_vpc.public_subnets_cidr_blocks)
}

# First we setup all networking related concerns, like a VPC and default security groups.
# External modules can be restrictive at times, but they're also quite convenient so...
module "main_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name = "main-vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.5.0/24", "10.0.10.0/24"]
  public_subnets  = ["10.0.105.0/24", "10.0.110.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  create_database_subnet_group = false
  enable_dns_hostnames         = true
  enable_dns_support           = true

  tags = local.tags
}

# Security related stuff
# IAM
resource aws_iam_policy "bucket_access" {
  name        = "bootstrap_bucket_access"
  path        = "/terraform/"
  description = "Allows instances of the bootstrap test stack to access it's S3 bucket"
  policy      = data.aws_iam_policy_document.bucket_access.json
}

resource "aws_iam_role" "bucket_access" {
  name               = "bucket-access-role"
  path               = "/terraform/instances/"
  assume_role_policy = data.aws_iam_policy_document.this_role.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.bucket_access.name
  policy_arn = aws_iam_policy.bucket_access.arn
}

resource "aws_iam_instance_profile" "bucket_access" {
  path = "/terraform/"
  role = aws_iam_role.bucket_access.name
}

# SSH and Chef
resource tls_private_key "ephemeral" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file "ephemeral_key" {
  content         = tls_private_key.ephemeral.private_key_pem
  filename        = "${path.module}/ephemeral.pem"
  file_permission = "0600"
}

resource tls_private_key "chef_admin_client" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource aws_key_pair "ephemeral" {
  key_name_prefix = "ephemeral"
  public_key      = tls_private_key.ephemeral.public_key_openssh
}

# An S3 bucket to hold some static assets, like chef policy artifacts
resource "aws_s3_bucket" "static_assets" {
  bucket_prefix = "bootstrap-test"
  force_destroy = true
  tags          = local.tags

  provisioner "local-exec" {
    command = "aws2 s3 cp ./policy_artifacts/${var.omnibus_zero_package} s3://${aws_s3_bucket.static_assets.id}/"
  }
}

# A bastion
resource aws_security_group "bastion" {
  name_prefix = "bastion"
  description = "Allows external ssh"
  vpc_id      = module.main_vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource aws_instance "bastion" {
  instance_type          = "t3.nano"
  ami                    = data.aws_ami.centos7.id
  key_name               = aws_key_pair.ephemeral.key_name
  subnet_id              = module.main_vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]
  tags                   = merge(var.tags, { "Name" = "bastion" })
  root_block_device {
    delete_on_termination = true
  }
}

# The bastion's address must be predictable, so we create a DNS record for it
# Alternatively, an EIP could be used but it would need to be managed in another template or manually
resource aws_route53_record "bastion" {
  zone_id = var.r53_zone_id
  name    = "bootstrap_bastion.${data.aws_route53_zone.this.name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.bastion.public_ip]
}

resource aws_security_group "chef-server" {
  name_prefix = "chef-server"
  description = "Allows https"
  vpc_id      = module.main_vpc.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.5.0/24", "10.0.10.0/24", "10.0.105.0/24", "10.0.110.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource aws_instance "chef-server" {
  instance_type          = "t3.medium"
  ami                    = data.aws_ami.centos7.id
  key_name               = aws_key_pair.ephemeral.key_name
  subnet_id              = module.main_vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.chef-server.id]
  user_data              = data.template_file.chef_server_ud.rendered
  # Using a static address makes things simpler in kitchen and inspec
  private_ip = "10.0.5.101"
  provisioner "file" {
    content     = tls_private_key.chef_admin_client.public_key_pem
    destination = "/tmp/chef_admin.pub"
    connection {
      user                = "centos"
      host                = self.private_ip
      private_key         = tls_private_key.ephemeral.private_key_pem
      bastion_host        = aws_instance.bastion.public_ip
      bastion_user        = "centos"
      bastion_private_key = tls_private_key.ephemeral.private_key_pem
    }
  }
  # Wait until cloud-init is done setting up Chef and the test user/org
  provisioner "remote-exec" {
    inline = [
      "until [[ -e /var/lib/cloud/instance/boot-finished ]]; do",
      "sleep 5",
      "done",
    ]
    connection {
      user                = "centos"
      host                = self.private_ip
      private_key         = tls_private_key.ephemeral.private_key_pem
      bastion_host        = aws_instance.bastion.public_ip
      bastion_user        = "centos"
      bastion_private_key = tls_private_key.ephemeral.private_key_pem
    }
  }
  root_block_device {
    delete_on_termination = true
  }
  tags = merge(var.tags, { "Name" = "chef-server" })
}

resource aws_instance "omnibus" {
  instance_type          = "t3.medium"
  ami                    = data.aws_ami.centos7.id
  key_name               = aws_key_pair.ephemeral.key_name
  subnet_id              = module.main_vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.nodes.id]
  user_data              = data.template_cloudinit_config.omnibus_ud.rendered
  iam_instance_profile   = aws_iam_instance_profile.bucket_access.name
  # The Chef admin user key to use for all bootstrap operations
  provisioner "file" {
    content     = tls_private_key.chef_admin_client.private_key_pem
    destination = "/tmp/chef_admin.pem"
    connection {
      host                = self.private_ip
      user                = "centos"
      private_key         = tls_private_key.ephemeral.private_key_pem
      bastion_host        = aws_instance.bastion.public_ip
      bastion_user        = "centos"
      bastion_private_key = tls_private_key.ephemeral.private_key_pem
    }
  }
  # The ssh key to use when bootstraping Unix-like nodes
  provisioner "file" {
    content     = tls_private_key.ephemeral.private_key_pem
    destination = "/tmp/ephemeral.pem"
    connection {
      host                = self.private_ip
      user                = "centos"
      private_key         = tls_private_key.ephemeral.private_key_pem
      bastion_host        = aws_instance.bastion.public_ip
      bastion_user        = "centos"
      bastion_private_key = tls_private_key.ephemeral.private_key_pem
    }
  }
  # Wait for cloud-init to complete before moving on to Inspec
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod 0600 /tmp/ephemeral.pem",
      "sudo yum install -y git",
      "git clone --depth 1 -b ${var.chef_repo_branch} ${var.chef_repo_url} /home/centos/chef",
      "until [[ -e /var/lib/cloud/instance/boot-finished ]]; do",
      "sleep 5",
      "done",
    ]
    connection {
      user                = "centos"
      host                = self.private_ip
      private_key         = tls_private_key.ephemeral.private_key_pem
      bastion_host        = aws_instance.bastion.public_ip
      bastion_user        = "centos"
      bastion_private_key = tls_private_key.ephemeral.private_key_pem
    }
  }
  depends_on = [aws_instance.chef-server, aws_instance.nix_nodes, aws_instance.win_nodes]
  root_block_device {
    delete_on_termination = true
  }
  tags = merge(var.tags, { "Name" = "omnibus_node" })
}

resource aws_security_group "nodes" {
  name_prefix = "chef-nodes"
  description = "Allows ssh/winrm"
  vpc_id      = module.main_vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.5.0/24", "10.0.10.0/24", "10.0.105.0/24", "10.0.110.0/24"]
  }

  ingress {
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["10.0.5.0/24", "10.0.10.0/24", "10.0.105.0/24", "10.0.110.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource aws_instance "nix_nodes" {
  count = 2

  instance_type          = "t3.nano"
  ami                    = local.nix_ami_ids[count.index]
  key_name               = aws_key_pair.ephemeral.key_name
  subnet_id              = module.main_vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.nodes.id]
  tags                   = merge(var.tags, { "Name" = "nix_node_${count.index}" })
  user_data              = templatefile("templates/add_sudo_user.sh.tpl", { public_key = tls_private_key.ephemeral.public_key_openssh })
  root_block_device {
    delete_on_termination = true
  }
}

resource aws_instance "win_nodes" {
  count                  = 1
  instance_type          = "t3.medium"
  ami                    = "ami-09f2114fecbe506e2"
  key_name               = aws_key_pair.ephemeral.key_name
  subnet_id              = module.main_vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.nodes.id]
  user_data              = base64encode(file("files/enable_winrm.bat"))
  get_password_data      = true
  root_block_device {
    delete_on_termination = true
  }
  tags = merge(var.tags, { "Name" = "win_node_${count.index}" })
}
