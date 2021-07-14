module "networking" {

    source                  = "./modules/networking"
    region                  = "${var.region}"
    environment             = "${var.environment}"
    vpc_cidr                = "${var.vpc_cidr}"
    public_subnets_cidr     = "${var.public_subnet_cidr}"
    private_subnets_cidr    = "${var.private_subnets_cidr}"
    availability_zones      = "${var.availability_zones}"
  
}