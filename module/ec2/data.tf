data "aws_ami" "dlami_gpu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    # Шукаємо офіційний Deep Learning образ з PyTorch
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

data "aws_vpc" "jumpserver" {
  default = (var.use_default_vpc == true) ? true : false
  id      = var.vpc_id
}

data "aws_security_group" "jumpserver" {
  name   = "default"
  vpc_id = data.aws_vpc.jumpserver.id
}

#data "aws_ip_ranges" "frankfurt_ec2_instance_connect" {
#  regions  = ["eu-central-1"]
#  services = ["ec2_instance_connect"]
#}