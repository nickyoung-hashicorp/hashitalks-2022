### Variables ###

variable "prefix" {
  description = "Prefix that will be added to all taggable resources"
  default = "hashitalks2022"
}

variable "subnet_prefix_a" {
  description = "The address prefix to use for the subnet in availability zone a"
  default     = "10.0.1.0/24"
}

variable "subnet_prefix_b" {
  description = "The address prefix to use for the subnet in availability zone b"
  default     = "10.0.2.0/24"
}

variable "instance_type" {
  description = "Specifies the AWS instance type."
  default     = "t2.medium"
}

### Resources ###

resource "aws_subnet" "vault-a" {
  vpc_id     = aws_vpc.vault.id
  cidr_block = var.subnet_prefix_a
  availability_zone = "us-west-2a"

  tags = {
    name = "${var.prefix}-subnet-a"
  }
}

resource "aws_subnet" "vault-b" {
  vpc_id     = aws_vpc.vault.id
  cidr_block = var.subnet_prefix_b
  availability_zone = "us-west-2b"

  tags = {
    name = "${var.prefix}-subnet-b"
  }
}

resource "aws_db_subnet_group" "mysql" {
  name       = "${var.prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.vault-a.id, aws_subnet.vault-b.id]

  tags = {
    Name = "${var.prefix}-db-subnet-group"
  }
}

resource "aws_security_group" "vault" {
  name = "${var.prefix}-security-group"

  vpc_id = aws_vpc.vault.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8200
    to_port     = 8201
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.prefix}-security-group"
  }
}

resource "aws_internet_gateway" "vault" {
  vpc_id = aws_vpc.vault.id

  tags = {
    Name = "${var.prefix}-internet-gateway"
  }
}

resource "aws_route_table" "vault" {
  vpc_id = aws_vpc.vault.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vault.id
  }
}

resource "aws_route_table_association" "vault-a" {
  subnet_id      = aws_subnet.vault-a.id
  route_table_id = aws_route_table.vault.id
}

resource "aws_route_table_association" "vault-b" {
  subnet_id      = aws_subnet.vault-b.id
  route_table_id = aws_route_table.vault.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_eip" "vault" {
  instance = aws_instance.vault.id
  vpc      = true
}

resource "aws_eip_association" "vault" {
  instance_id   = aws_instance.vault.id
  allocation_id = aws_eip.vault.id
}

resource "aws_instance" "vault" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.vault.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.vault-a.id
  vpc_security_group_ids      = [aws_security_group.vault.id]
  iam_instance_profile        = aws_iam_instance_profile.vault-dynamodb-instance-profile.name

  tags = {
    Name = "${var.prefix}-vault-instance"
  }

  depends_on = [
    aws_dynamodb_table.vault_dynamo,
  ]
}

resource "null_resource" "configure-vault" {
  depends_on = [aws_eip_association.vault]

  triggers = {
    build_number = timestamp()
  }

  provisioner "file" {
    source      = "./files/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.vault.private_key_pem
      host        = aws_eip.vault.public_ip
    }
  }
}

resource "tls_private_key" "vault" {
  algorithm = "RSA"
}

locals {
  private_key_filename = "${var.prefix}-ssh-key.pem"
}

resource "aws_key_pair" "vault" {
  key_name   = local.private_key_filename
  public_key = tls_private_key.vault.public_key_openssh

  provisioner "local-exec" { # Create "myKey.pem" to your computer!!
    command = <<-EOT
      echo '${tls_private_key.vault.private_key_pem}' > ./privateKey.pem
      chmod 400 ./privateKey.pem
    EOT
  }
}

# Creates IAM Policy to access provisioned DynamoDB table
resource "aws_iam_policy" "vault-dynamodb-policy" {
  name        = "${var.prefix}-vault-dynamodb-policy"
  description = "Access DynamoDB from Vault running in EC2"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
      "Action": [
        "dynamodb:DescribeLimits",
        "dynamodb:DescribeTimeToLive",
        "dynamodb:ListTagsOfResource",
        "dynamodb:DescribeReservedCapacityOfferings",
        "dynamodb:DescribeReservedCapacity",
        "dynamodb:ListTables",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:CreateTable",
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:GetRecords",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:UpdateItem",
        "dynamodb:Scan",
        "dynamodb:DescribeTable"
      ],
      "Effect": "Allow",
      "Resource": [ "arn:aws:dynamodb:*:*:table/vault-backend" ]
    }
]
}
EOF
}

# Creates Role, referencing "vault-dynamodb-policy"
resource "aws_iam_role" "vault-dynamodb-role" {
  name = "${var.prefix}-vault-dynamodb-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Attaches "vault-dynamodb-policy" to "vault-dynamodb-role"
resource "aws_iam_role_policy_attachment" "vault-dynamodb-policy-attach" {
  role       = aws_iam_role.vault-dynamodb-role.name
  policy_arn = aws_iam_policy.vault-dynamodb-policy.arn
}

resource "aws_iam_instance_profile" "vault-dynamodb-instance-profile" {
  name = "${var.prefix}-vault-dynamodb-instance-profile"
  role = aws_iam_role.vault-dynamodb-role.name
}