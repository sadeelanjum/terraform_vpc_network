variable "project" {
  type = string
  default = "test"
  description = "Project name"
}
 #############################
#          VPC Vars
#############################
 
variable "vpc_cidr" {
  type = string
  description = "IP CIDR for vpc"
}
variable "enable_dns_hostnames" {
  type = bool
  default = true
  description = "True to anable dns host names, false otherwise"
}

variable "enable_dns_support" {
  type = bool
  default = true
  description = "True to anable dns support, false otherwise"
}

variable "public_subnet_cidrs" {
  type = list(string)
  description = "List of cidrs for public subnets"
}

variable "private_subnet_cidrs" {
  type = list(string)
  description = "List of cidrs for private subnets"
}
variable "protected_subnet_cidrs" {
  type = list(string)
  description = "List of cidrs for protected subnets"
}