### Resources ###

resource "aws_vpc" "vault" {
  cidr_block           = var.address_space
  enable_dns_hostnames = true

  tags = {
    name = "${var.prefix}-vault-vpc"
  }
}