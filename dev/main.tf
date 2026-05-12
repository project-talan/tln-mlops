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

module "llm_instances" {
  source = "../module/external-llm-module"
  for_each = { for inst in var.instances : inst.name => inst }

  instance_name  = each.value.name
  instance_type  = each.value.instanceType
  disk_size      = each.value.disk-size
  allowed_models = each.value.models # Passes the list of models directly

  //network configuration
  use_default_vpc  = false
  vpc_id           = module.vpc.vpc_id
  subnet_id        = module.vpc.private_subnets[0]

  tags             = var.instance_tags  //module.shared.tags

  //load first model in memory
  model            = each.value.models[0]

}