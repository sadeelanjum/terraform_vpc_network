data "aws_region" "aws-region" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {

  default_tags = {
    managed_by = "terraform"
    project = var.project
    environment = var.env
  }
  aws_region = data.aws_region.aws-region.name
}


resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags                 = merge(local.default_tags, 
                            tomap(
                                {"Name" = "${var.project}-${var.env}-vpc"}
                            )
                        )
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.default_tags, 
              tomap(
                  {"Name" =  "${var.project}-${var.env}-${aws_vpc.vpc.id}-igw"}
              )
          )
}



############################################
#              PUBLIC SUBNETS              #
############################################
resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags                    = merge(local.default_tags, 
                              tomap(
                                  {"Name" =   "${var.project}-${var.env}-${aws_vpc.vpc.id}-public-${count.index + 1}"}
                              )
                           )
}

############################################
#             PRIVATE SUBNETS              #
############################################
resource "aws_subnet" "private_subnet" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags                    = merge(local.default_tags, 
                              tomap(
                                  {"Name" =   "${var.project}-${var.env}-${aws_vpc.vpc.id}-private-${count.index + 1}"}
                              )
                          )
}

############################################
#             PROTECTED SUBNETS              #
############################################
resource "aws_subnet" "protected_subnet" {
  count                   = length(var.protected_subnet_cidrs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.protected_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags                    = merge(local.default_tags, 
                              tomap(
                                  {"Name" =   "${var.project}-${var.env}-${aws_vpc.vpc.id}-protected-${count.index + 1}"}
                              )
                          )
}
############################################
#                EIP & NAT                 #
############################################
resource "aws_eip" "eip" {
  depends_on = [aws_internet_gateway.igw]
  count      =  length(var.private_subnet_cidrs)
  vpc        = true
  tags       = merge(local.default_tags, 
                  tomap(
                      {"Name" =   "${var.project}-${var.env}-${aws_vpc.vpc.id}-eip-${count.index + 1}"}
                  )
              )
}

resource "aws_nat_gateway" "nat" {
  depends_on    = [aws_internet_gateway.igw]
  count         = length(var.private_subnet_cidrs)
  allocation_id = element(aws_eip.eip[*].id, count.index)
  subnet_id     =  element(aws_subnet.public_subnet[*].id, count.index)
  tags          = merge(local.default_tags, 
                      tomap(
                          {"Name" =   "${var.project}-${var.env}-${aws_vpc.vpc.id}-nat-${count.index + 1}"}
                      )
                  )  
}

############################################
#    PUBLIC ROUTE TABLE                    #
############################################

resource "aws_route_table" "public_rt" {
  count  =  length(var.public_subnet_cidrs)
  vpc_id =  aws_vpc.vpc.id
  tags   = merge(local.default_tags, 
            tomap(
                {"Name" =  "${var.project}-${var.env}-${aws_vpc.vpc.id}-public-rt-${count.index + 1}"}
            )
        )
}

resource "aws_route" "public_route" {
  depends_on             = [aws_route_table.public_rt]
  count                  = length(var.public_subnet_cidrs)
  route_table_id         = element(aws_route_table.public_rt[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_rt_subnet_association" {
  depends_on     = [aws_route_table.public_rt, aws_subnet.public_subnet]
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
  route_table_id = element(aws_route_table.public_rt[*].id, count.index)
}

############################################
#    PRIVATE ROUTE TABLE
############################################

resource "aws_route_table" "private_rt" {
  count  =  length(var.public_subnet_cidrs)
  vpc_id =  aws_vpc.vpc.id
  tags   = merge(local.default_tags, 
            tomap(
                {"Name" =  "${var.project}-${var.env}-${aws_vpc.vpc.id}-private-rt-${count.index + 1}"}
            )
        )
}

resource "aws_route" "private_route" {
  count                  = length(var.public_subnet_cidrs)
  route_table_id         = aws_route_table.private_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat[*].id, count.index)
}

resource "aws_route_table_association" "private_rt_subnet_association" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnet[*].id, count.index)
  route_table_id = element(aws_route_table.private_rt[*].id, count.index)
}


############################################
#    PROTECTED ROUTE TABLE
############################################

resource "aws_route_table" "protected_rt" {
  count  =  length(var.public_subnet_cidrs)
  vpc_id =  aws_vpc.vpc.id
  tags   = merge(local.default_tags, 
            tomap(
                {"Name" =  "${var.project}-${var.env}-${aws_vpc.vpc.id}-protected-rt-${count.index + 1}"}
            )
        )
}

resource "aws_route" "protected_route" {
  count                  = length(var.public_subnet_cidrs)
  route_table_id         = aws_route_table.protected_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat[*].id, count.index)
}

resource "aws_route_table_association" "protected_rt_subnet_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.protected_subnet[*].id, count.index)
  route_table_id = element(aws_route_table.protected_rt[*].id, count.index)
}





############################################
#             PUBLIC NACL
############################################
resource "aws_network_acl" "public_nacl" {
  count  =  length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.vpc.id

  egress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags   = merge(local.default_tags, 
            tomap(
                {"Name" =  "${var.project}-${var.env}-${aws_vpc.vpc.id}-public-nacl-${count.index + 1}"}
            )
        )
}

resource "aws_network_acl_association" "public_nacl_subnet_association" {
  count          =  length(var.public_subnet_cidrs)
  network_acl_id = element(aws_network_acl.public_nacl[*].id, count.index)
  subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
}


############################################
#             PRIVATE NACL
############################################
resource "aws_network_acl" "private_nacl" {
  count  =  length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.vpc.id

  egress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags   = merge(local.default_tags, 
            tomap(
                {"Name" =  "${var.project}-${var.env}-${aws_vpc.vpc.id}-private-nacl-${count.index + 1}"}
            )
        )
}

resource "aws_network_acl_association" "private_nacl_subnet_association" {
  count          =  length(var.public_subnet_cidrs)
  network_acl_id = element(aws_network_acl.private_nacl[*].id, count.index)
  subnet_id      = element(aws_subnet.private_subnet[*].id, count.index)
}

############################################
#             PROTECTED NACL
############################################
resource "aws_network_acl" "protected_nacl" {
  count  =  length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.vpc.id

  egress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags   = merge(local.default_tags, 
            tomap(
                {"Name" =  "${var.project}-${var.env}-${aws_vpc.vpc.id}-public-nacl-${count.index + 1}"}
            )
        )
}
resource "aws_network_acl_association" "protected_nacl_subnet_association" {
  count          =  length(var.public_subnet_cidrs)
  network_acl_id = element(aws_network_acl.protected_nacl[*].id, count.index)
  subnet_id      = element(aws_subnet.protected_subnet[*].id, count.index)
}