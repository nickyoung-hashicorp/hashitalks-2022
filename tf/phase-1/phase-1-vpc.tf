### Resources ###

resource "aws_default_vpc" "vault" {
  tags = {
    Name = "Default VPC"
  }
}