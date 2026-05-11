module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    version = "6.6.1"

    name = "POC_TEST_g4dn"
    cidr = var.vpc_cidr
    azs  = data.aws_availability_zones.available.names

    private_subnets  = var.private_subnets
    public_subnets   = var.public_subnets

    enable_nat_gateway   = true
    #single_nat_gateway   = true
    enable_dns_hostnames = true
    #enable_dns_support   = true


}

module "bastion" {
  source = "../module/jumpserver"
  use_default_vpc  = false

  resources_prefix = "${var.group_id}-${var.env_id}-bastion" //"${module.shared.prefix_env}-bastion"
  files_prefix     = "${var.group_id}-${var.env_id}-bastion"
  vpc_id           = module.vpc.vpc_id
  subnet_id        = module.vpc.public_subnets[0]
  instance_type    = var.bastion_instance_type
  custom_packages  = var.bastion_custom_packages
  tags             = var.instance_tags
}

variable "model_names" {
  description = "list of models to run on ec2"
  default = ["llama3", "mistral"]
  type = list(string)
}

module "ec2" {
  source = "../module/ec2"
  //for_each = toset(var.model_names)
  # Create map, where key — name, value — index + 1
  for_each = { for i, name in var.model_names : name => i + 1 }

  use_default_vpc  = false

  resources_prefix = "llm-node-${each.value}-${each.key}"
  files_prefix     = "llm-node-${each.value}-${each.key}"
  vpc_id           = module.vpc.vpc_id
  subnet_id        = module.vpc.private_subnets[0]
  instance_type    = "g4dn.xlarge"
  tags             = var.instance_tags  //module.shared.tags
  custom_packages  = var.bastion_custom_packages
  model            = each.key
  models           = var.model_names
  #close access to private subnet cidr only
  //allowed_ssh_cidr_blocks = module.vpc.private_subnets_cidr_blocks
}

#Configuration Example
#instances:
#- name: llm-node-1
#instanceType: g5.xlarge
#models:
#- llama3
#- mistral
#- name: llm-node-2
#instanceType: g5.2xlarge
#models:
#- codellama
#- qwen