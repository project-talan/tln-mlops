data "aws_ami" "dlami_gpu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    # Search oficial ami with nvidia driver
    values = ["*Deep Learning*PyTorch*2.*Ubuntu*22.04*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "ai_server" {
  default = (var.use_default_vpc == true) ? true : false
  id      = var.vpc_id
}

data "aws_security_group" "jumpserver" {
  name   = "default"
  vpc_id = data.aws_vpc.ai_server.id
}