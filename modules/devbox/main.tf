terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet" "private" {
  for_each = toset(var.private_subnet_ids)
  id       = each.value
}

data "aws_ami" "ubuntu_2404" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

locals {
  enabled_engineers = {
    for key, engineer in var.engineers : key => engineer
    if engineer.enabled
  }

  subnet_ids = var.private_subnet_ids

  ami_id = coalesce(var.ami_id, try(data.aws_ami.ubuntu_2404[0].id, null))

  ssh_cidr_blocks = var.allowed_ssh_cidr_blocks == null ? [data.aws_vpc.selected.cidr_block] : var.allowed_ssh_cidr_blocks

  base_tags = merge(
    var.tags,
    {
      Environment = var.environment
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
      Project     = "cloud-workspace"
    }
  )
}

resource "aws_security_group" "devbox" {
  name_prefix = "devbox-${var.environment}-"
  description = "Private SSH access for ${var.environment} dev boxes"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from private network"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.ssh_cidr_blocks
  }

  egress {
    description = "Outbound access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, {
    Name = "devbox-${var.environment}-ssh"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "devbox" {
  name_prefix = "devbox-${var.environment}-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.base_tags, {
    Name = "devbox-${var.environment}"
  })
}

resource "aws_iam_instance_profile" "devbox" {
  name_prefix = "devbox-${var.environment}-"
  role        = aws_iam_role.devbox.name

  tags = merge(local.base_tags, {
    Name = "devbox-${var.environment}"
  })
}

resource "aws_key_pair" "engineer" {
  for_each = local.enabled_engineers

  key_name_prefix = "devbox-${var.environment}-${each.key}-"
  public_key      = each.value.ssh_public_key

  tags = merge(local.base_tags, each.value.tags, {
    Name     = "devbox-${var.environment}-${each.key}"
    Engineer = each.value.username
  })
}

resource "aws_ebs_volume" "workspace" {
  for_each = local.enabled_engineers

  availability_zone = data.aws_subnet.private[local.subnet_ids[each.value.subnet_index % length(local.subnet_ids)]].availability_zone
  type              = "gp3"
  size              = coalesce(each.value.workspace_size_gb, var.default_workspace_size_gb)
  encrypted         = true

  tags = merge(local.base_tags, each.value.tags, {
    Name     = "devbox-${var.environment}-${each.key}-workspace"
    Engineer = each.value.username
    Role     = "workspace"
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_instance" "devbox" {
  for_each = local.enabled_engineers

  ami                         = local.ami_id
  instance_type               = coalesce(each.value.instance_type, var.default_instance_type)
  subnet_id                   = local.subnet_ids[each.value.subnet_index % length(local.subnet_ids)]
  vpc_security_group_ids      = [aws_security_group.devbox.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.devbox.name
  key_name                    = aws_key_pair.engineer[each.key].key_name
  user_data_replace_on_change = true

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    username            = each.value.username
    ssh_public_key      = each.value.ssh_public_key
    workspace_volume_id = aws_ebs_volume.workspace[each.key].id
  })

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size_gb
    encrypted   = true
  }

  tags = merge(local.base_tags, each.value.tags, {
    Name     = "devbox-${var.environment}-${each.key}"
    Engineer = each.value.username
  })

  volume_tags = merge(local.base_tags, each.value.tags, {
    Name     = "devbox-${var.environment}-${each.key}-root"
    Engineer = each.value.username
    Role     = "root"
  })
}

resource "aws_volume_attachment" "workspace" {
  for_each = local.enabled_engineers

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.workspace[each.key].id
  instance_id = aws_instance.devbox[each.key].id
}
