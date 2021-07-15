region                  = "eu-west-2"
environment             = "AT"
vpc_cidr                = "100.0.0.0/16"
public_subnets_cidr     = ["100.0.1.0/24"]
private_subnets_cidr    = ["100.0.2.0/24"]
availability_zones      = ["eu-west-2a", "eu-west-2b"]

#RHEL8
#ami = "ami-0ad8ecac8af5fc52b"

#AnsibleTower 3.8.3.1 AnsibleTower Instance
ami           = "ami-0bbfd52eab6ff3e75"
instance_type = "m4.large"

key_name = "ram-ansibletower"
key_location = "/home/centos/aws-ansibletower/ram-ansibletower.pem"