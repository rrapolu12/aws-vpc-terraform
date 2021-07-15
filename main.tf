/*======================================= The VPC =====================================*/
resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${var.environment}-vpc"
    Environment = "${var.environment}"
  }
}

/*========================  Internet gateway for the public subnet ====================*/
/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name        = "${var.environment}-igw"
    Environment = "${var.environment}"
  }
}

#==========================   Elastic IP for NAT Gateway  =============================#
/* Elastic IP for NAT */
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.ig]
}

#==========================   NAT Gateway  =============================================#
/* NAT */
resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${element(aws_subnet.public_subnet.*.id, 0)}"
  depends_on    = [aws_internet_gateway.ig]
  tags = {
    Name        = "nat"
    Environment = "${var.environment}"
  }
}

#==========================   Public subnet  ============================================#
/* Public subnet */
resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  count                   = "${length(var.public_subnets_cidr)}"
  cidr_block              = "${element(var.public_subnets_cidr,   count.index)}"
  availability_zone       = "${element(var.availability_zones,   count.index)}"
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-      public-subnet"
    Environment = "${var.environment}"
  }
}

#==========================   Private subnet  ============================================#
/* Private subnet */
resource "aws_subnet" "private_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  count                   = "${length(var.private_subnets_cidr)}"
  cidr_block              = "${element(var.private_subnets_cidr, count.index)}"
  availability_zone       = "${element(var.availability_zones,   count.index)}"
  map_public_ip_on_launch = false
  tags = {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-private-subnet"
    Environment = "${var.environment}"
  }
}

#==========================   Routing table for private subnet  ===========================#
/* Routing table for private subnet */
resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name        = "${var.environment}-private-route-table"
    Environment = "${var.environment}"
  }
}
resource "aws_route" "private_nat_gateway" {
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat.id}"
}

#==========================   Routing table for public subnet  ===========================#
/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name        = "${var.environment}-public-route-table"
    Environment = "${var.environment}"
  }
}
resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.ig.id}"
}

#==========================   Route table associations  ===========================#
/* Route table associations */
resource "aws_route_table_association" "public" {
  count          = "${length(var.public_subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}
resource "aws_route_table_association" "private" {
  count          = "${length(var.private_subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}


/*========================  VPC's Default Security Group ==========================*/
/*==== VPC's Default Security Group ======*/
resource "aws_security_group" "default" {
  name        = "${var.environment}-default-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = "${aws_vpc.vpc.id}"
  depends_on  = [aws_vpc.vpc]
  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
  
  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }
  tags = {
    Environment = "${var.environment}"
  }
}

#================== Create a Security Group for Ansible Tower =====================#
# Creating a Security Group for WordPress
resource "aws_security_group" "ANSIBLETOWER-SG" {

  #subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  depends_on = [
    aws_vpc.vpc,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet
  ]

  description = "HTTP, HTTPS, PING, SSH"

  # Name of the security Group!
  name = "ansibletower-sg"
  
  # VPC ID in which Security group has to be created!
  vpc_id = aws_vpc.vpc.id

  # Created an inbound rule for Ansible Tower HTTP access!
  ingress {
    description = "HTTP for AnsibleTower"
    from_port   = 80
    to_port     = 80

    # Here adding tcp instead of http, because http in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Created an inbound rule for Ansible Tower HTTPS access!
  ingress {
    description = "HTTPS for AnsibleTower"
    from_port   = 443
    to_port     = 443

    # Here adding tcp instead of https, because https in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Created an inbound rule for ping
  ingress {
    description = "Ping"
    from_port   = 0
    to_port     = 0
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Created an inbound rule for SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22

    # Here adding tcp instead of ssh, because ssh in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outward Network Traffic for the WordPress
  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#==================================== Security Group for POSTGRESql Instance in Private Subnet ################################
# Creating security group for POSTGRESql, this will allow access only from the instances having the security group created above.

resource "aws_security_group" "POSTGRESql-SG" {

  depends_on = [
    aws_vpc.vpc,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet,
    aws_security_group.ANSIBLETOWER-SG
  ]

  description = "POSTGRESql Access only from the AnsibleTower Instances!"
  name = "postgresql-sg"
  vpc_id = aws_vpc.vpc.id

  # Created an inbound rule for POSTGRESql
  ingress {
    description = "POSTGRESql Access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.ANSIBLETOWER-SG.id]
  }

  egress {
    description = "output from POSTGRESql"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#======================= Security Group for anyone to connect Bastion  ===========================#
# Creating security group for Bastion Host/Jump Box

resource "aws_security_group" "BastionHost-SG" {

   depends_on = [
    aws_vpc.vpc,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet
  ]

  description = "POSTGRESql Access only from the AnsibleTower Instances!"
  name = "bastion-host-sg"
  vpc_id = aws_vpc.vpc.id

  # Created an inbound rule for Bastion Host SSH
  ingress {
    description = "Bastion Host SG"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "output from Bastion Host"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#======================= Security Group for POSTGRESql which allows only BastionHost to connect and do the updates  ===========================#
# Creating security group for POSTGRESql Bastion Host Access

resource "aws_security_group" "BastionHost-SG-SSH" {

   depends_on = [
    aws_vpc.vpc,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet,
    aws_security_group.BastionHost-SG
  ]

  description = "POSTGRESql Access only from the AnsibleTower Instances!"
  name = "postgresql-sg-bastion-host"
  vpc_id = aws_vpc.vpc.id

  # Created an inbound rule for Bastion Host SSH
  ingress {
    description = "Bastion Host SG"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.BastionHost-SG.id]
  }

  egress {
    description = "output from POSTGRESql BastionHost"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#=============================== Creating a VM for Ansible Tower =================================#
# Creating an AWS instance for the Webserver!

resource "aws_instance" "ansibletower-vm" {

   depends_on = [
    aws_vpc.vpc,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet,
    aws_security_group.BastionHost-SG,
    aws_security_group.BastionHost-SG-SSH
  ]

  
  # AMI ID [I have used my custom AMI which has some softwares pre installed]

  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  
  #subnet_id = "aws_subnet.public_subnet[id]"
  subnet_id = "${element(aws_subnet.public_subnet.*.id, 0)}"
  #"${element(aws_subnet.public_subnet.*.id, count.index)}"

  # Keyname and security group are obtained from the reference of their instances created above!
  # Here I am providing the name of the key which is already uploaded on the AWS console.
  key_name = "${var.key_name}"
  
  # Security groups to use!
  vpc_security_group_ids = [aws_security_group.ANSIBLETOWER-SG.id]

  tags = {
   Name = "AnsibleTower_From_Terraform"
  }

  # Installing required softwares into the system!
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("${var.key_location}")
    host = aws_instance.ansibletower-vm.public_ip
  }

  # Code for installing the softwares!
  provisioner "remote-exec" {
    inline = [
        "sudo yum update -y",
        "sudo yum install python-3 -y",
        "alternatives — set python /usr/bin/python3",
        "sudo yum install python3-pip -y",
        "pip2 install ansible --user",
        "ansible version",
        "sudo yum install wget -y",
        "mkdir ansibletowerinstall",
        "cd ansibletowerinstall",
        "wget https://releases.ansible.com/ansible-tower/setup/ansible-tower-setup-latest.tar.gz",
        "tar xvzf ansible-tower-setup-latest.tar.gz"

    ]
  }
}