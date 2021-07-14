variable "region" {
    description = "AWS Europe West 2 London region"
#    default = "eu-west-2" // this will be declared in terraform.tfvars
}

variable "environment" {
    description = "This is Ansible Tower Environment and Abbrevated as AT"
}

variable "vpc_cidr" {
    description = "This defines the CIDR Range for VPC"
}

variable "public_subnets_cidr" {
    description = "This Defines the CIDR Range for Public Subnet"
}

variable "public_subnets_cidr" {
    description = "This Defines the CIDR Range for Public Subnet"
}

variable "availability_zones" {
    description = "This Defines the Availability Zones for VPC"
}