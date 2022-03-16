#Command to run
#terraform apply -var-file 'staging.tfvars'


data "aws_region" "aws-region" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
locals {
    account_id = data.aws_caller_identity.current.account_id
    aws_region = data.aws_region.aws-region.name
    default_tags = {
      "project" = var.project
      "Environment" = "${terraform.workspace}"
    }
  
}

/* terraform {
  #Following values have to be hard coded
  backend "s3" {
    bucket         = "srechallenge-dev-tf-backend-eu-west-1-708245457571"
    key            = "tf-state2/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "srechallenge-dev-tf-lock-eu-west-1"
    encrypt        = true
  }
} */

module "vpc" {
  source                 = "../modules/vpc"
  project                = var.project
  env                    = "${terraform.workspace}"
  vpc_cidr               = var.vpc_cidr
  enable_dns_hostnames   = var.enable_dns_hostnames
  enable_dns_support     = var.enable_dns_support
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  protected_subnet_cidrs = var.protected_subnet_cidrs
}