project                 = "srechallenge"
#############################
#    VPC Vars
#############################
 
vpc_cidr              = "172.31.0.0/16"
enable_dns_hostnames  = true
enable_dns_support    = true
public_subnet_cidrs   = ["172.31.0.0/24", "172.31.32.0/24" ]
private_subnet_cidrs  = ["172.31.2.0/24", "172.31.3.0/24"  ]
protected_subnet_cidrs = ["172.31.7.0/24", "172.31.9.0/24"]
