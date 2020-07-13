# Detect AZs available to your account in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "this" {
  zone_id = var.r53_zone_id
}

data "aws_iam_policy_document" "bucket_access" {
  statement {
    actions   = ["s3:ListBucket"]
    sid       = "BootstrapTestBucketList"
    effect    = "Allow"
    resources = [aws_s3_bucket.static_assets.arn]
  }
  statement {
    actions   = ["s3:GetObject"]
    sid       = "BootstrapTestBucketRead"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.static_assets.arn}/*"]
  }
}

data "aws_iam_policy_document" "this_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# User data for the Chef server. We use the old template_file data source instead
# of the new function because it looks cleaner when vars start to stack
data "template_file" "chef_server_ud" {
  template = file("./templates/chef_server_ud.sh.tpl")

  vars = {
  }
}

# Omnibus user-data
data "template_file" "omnibus_ud" {
  template = file("./templates/omnibus_ud.sh.tpl")

  vars = {
    bucket_name     = aws_s3_bucket.static_assets.id
    zero_package    = var.omnibus_zero_package
    chef_server_dns = aws_instance.chef-server.private_dns
    chef_repo_branch = var.chef_repo_branch
    chef_repo_url = var.chef_repo_url
  }
}

data "template_cloudinit_config" "omnibus_ud" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "00_init.sh"
    content_type = "text/x-shellscript"
    content      = file("${path.module}/files/init.sh")
  }

  part {
    filename     = "01_zero_package.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.omnibus_ud.rendered
  }
}

# Windows Omnibus user-data; since there's no cloud-config it's just one big template
data "template_file" "win_omnibus_ud" {
  template = file("./templates/omnibus_ud.ps1.tpl")

  vars = {
    bucket_name     = aws_s3_bucket.static_assets.id
    zero_package    = var.omnibus_zero_package
    chef_server_dns = aws_instance.chef-server.private_dns
    win_omnibus_override_pw = var.win_omnibus_override_pw
    chef_repo_branch = var.chef_repo_branch
    chef_repo_url = var.chef_repo_url
  }
}


# Fetch various AMIs
data "aws_ami" "centos7" {
  most_recent = true
  owners      = ["679593333241"] # The marketplace
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "is-public"
    values = ["true"]
  }
  filter {
    name = "product-code"
    # CentOS 7's code. No official Centos 8 AMI published as of this writing :(
    # https://wiki.centos.org/Cloud/AWS for other CentOS product codes
    values = ["aw0evgkw8e5c1q413zgy5pjce"]
  }
}

data "aws_ami" "win_2012r2" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "is-public"
    values = ["true"]
  }

  filter {
    name = "name"
    values = ["Windows_Server-2012-R2_RTM-English-64Bit-Base-*"]
  }

  filter {
    name = "platform"
    values = ["windows"]
  }
}

data "aws_ami" "nix_os_0" { # duplicates centos7, required for count logic
  most_recent = true
  owners      = ["679593333241"] # The marketplace
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "is-public"
    values = ["true"]
  }
  filter {
    name = "product-code"
    # CentOS 7's code. No official Centos 8 AMI published as of this writing :(
    # https://wiki.centos.org/Cloud/AWS for other CentOS product codes
    values = ["aw0evgkw8e5c1q413zgy5pjce"]
  }
}

data "aws_ami" "nix_os_1" { # debian buster
  most_recent = true
  owners      = ["136693071363"] # Debian Buster account
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "is-public"
    values = ["true"]
  }
}
