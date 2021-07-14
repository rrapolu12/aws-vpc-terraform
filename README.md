### Architecture of VPC Build
![alt text](./images/]/architecture.png?raw=true)
### Amazon Resources Created Using Terraform
        1. AWS VPC with 10.0.0.0/16 CIDR.
        2. Multiple AWS VPC public subnets would be reachable from the internet; which means traffic from the internet can 
           hit a machine in the public subnet.
        3. Multiple AWS VPC private subnets which mean it is not reachable to the internet directly without NAT Gateway.
        4. AWS VPC Internet Gateway and attach it to AWS VPC.
        5. Public and private AWS VPC Route Tables.
        6. AWS VPC NAT Gateway.
        7. Associating AWS VPC Subnets with VPC route tables.

