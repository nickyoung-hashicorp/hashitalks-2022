terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-1"
}

# Deploy VPC
module "vpc" {
  source = "./modules/vpc"
}

# Deploy DynamoDB
module "vault-dynamodb" {
  source = "./modules/dynamo-vault"
  table_name = "vault-backend"
  prefix = "hashitalks22"
  vpc_id = module.vpc.aws_vpc_id
}