locals {
  create_security_group = var.use_default_vpc ? false : true
  create_outbound_rule  = var.use_default_vpc ? false : true
  security_group_id     = var.use_default_vpc ? data.aws_security_group.jumpserver.id : aws_security_group.ai_server_sg[0].id
}

locals {
  ami_id = data.aws_ami.dlami_gpu.id

  flattened_custom_packages_map = flatten([
    for key, value in var.custom_packages :
    [key, value]
  ])

  tags = merge(
    {
      "Name" = "${var.resources_prefix}"
    },
    var.tags
  )
}

resource "aws_security_group" "ai_server_sg" {
  count       = local.create_security_group ? 1 : 0 #checking if we need to create a new security group or use the default one
  name        = "${var.resources_prefix}-sg"
  description = "Allow SSH access to the ai server"
  vpc_id      = data.aws_vpc.jumpserver.id

  tags = local.tags
}

#resource "aws_vpc_security_group_ingress_rule" "allow_ec2_instance_connect" {
#  security_group_id = local.security_group_id
#
#  # Використовуємо отримані діапазони
#  cidr_ipv4   = data.aws_ip_ranges.frankfurt_ec2_instance_connect.cidr_blocks[0]
#  from_port   = 22
#  to_port     = 22
#  ip_protocol = "tcp"
#  description = "Allow SSH access from EC2 Instance Connect service"
#}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  for_each = toset(var.allowed_ssh_cidr_blocks)

  security_group_id = local.security_group_id
  cidr_ipv4         = each.key
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  description       = "Allow SSH from ${each.key}"
  tags = merge(local.tags, {
    RuleDescription = "Allow SSH from ${each.key}"
  })
}

resource "aws_vpc_security_group_ingress_rule" "allow_Olama" {
  for_each = toset(var.allowed_ssh_cidr_blocks)

  security_group_id = local.security_group_id
  cidr_ipv4         = each.key
  from_port         = 11434
  ip_protocol       = "tcp"
  to_port           = 11434
  description       = "Allow Olama from ${each.key}"
  tags = merge(local.tags, {
    RuleDescription = "Allow Olama from ${each.key}"
  })
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  count             = local.create_outbound_rule ? 1 : 0 #default security group already allows all outbound
  security_group_id = local.security_group_id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # All protocols
  description       = "Allow all outbound traffic"
  tags = merge(local.tags, {
    RuleDescription = "Allow all outbound"
  })
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh" {
  key_name   = "${var.resources_prefix}-ssh-key"
  public_key = tls_private_key.ssh.public_key_openssh

  tags = local.tags
}

#resource "aws_eip" "static_ip" {
#  instance = aws_instance.ai_server.id
#  domain   = "vpc" # IP is used in VPC
#}

resource "aws_instance" "ai_server" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = false # if server needs public IP subnets must be public for this

  vpc_security_group_ids = [local.security_group_id]
  key_name               = aws_key_pair.ssh.key_name
  user_data_base64 = base64encode(templatefile("${path.module}/templates/template.sh.tftpl", {
    custom_packages = join(",", local.flattened_custom_packages_map)
    model = var.model
  }))



  user_data_replace_on_change = true

  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }
  root_block_device {
    encrypted   = true
    //volume_type = "gp3"
    volume_size = var.jumpserver_volume_size
  }

  tags = local.tags
}

# Add local file resources to save key and address
resource "local_sensitive_file" "ssh_private_key_pem" {
  filename        = "${var.files_prefix}-ssh-key.pem"
  file_permission = "400"
  content         = tls_private_key.ssh.private_key_pem
}

resource "local_sensitive_file" "ai_server_address" {
  filename        = "${var.files_prefix}.addr"
  file_permission = "400"
  content         = "ubuntu@${aws_instance.ai_server.public_ip}"
}
