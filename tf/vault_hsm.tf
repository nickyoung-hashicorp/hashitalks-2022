resource "aws_eip" "vault-hsm" {
  instance = aws_instance.vault-hsm.id
  vpc      = true
}

resource "aws_eip_association" "vault-hsm" {
  instance_id   = aws_instance.vault-hsm.id
  allocation_id = aws_eip.vault-hsm.id
}

resource "aws_instance" "vault-hsm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.vault.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.vault-a.id
  vpc_security_group_ids      = [aws_security_group.vault.id, aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.vault-hsm-instance-profile.name

  tags = {
    Name          = "${var.prefix}-vault-hsm-instance"
  }
}

resource "null_resource" "configure-vault-hsm" {
  depends_on = [aws_eip_association.vault-hsm]

  # triggers = {
  #   build_number = timestamp()
  # }

  provisioner "file" {
    source      = "./files/vault_hsm/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.vault.private_key_pem
      host        = aws_eip.vault-hsm.public_ip
    }
  }

    provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.vault.private_key_pem
      host        = aws_eip.vault-hsm.public_ip
    }
  }
}

# Provision CloudHSM
resource "aws_cloudhsm_v2_cluster" "cloudhsm_v2_cluster" {
  hsm_type   = "hsm1.medium"
  subnet_ids = [aws_subnet.vault-a.id]

  tags = {
    Name = "${var.prefix}-vault-cloudhsm"
  }
}

resource "aws_cloudhsm_v2_hsm" "cloudhsm_v2_hsm" {
  cluster_id        = aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.cluster_id
  subnet_id = aws_subnet.vault-a.id
}

# Creates IAM Policy to access provisioned CloudHSM
resource "aws_iam_policy" "vault-hsm-policy" {
  name        = "${var.prefix}-vault-hsm-policy"
  description = "Access CloudHSM from Vault running in EC2"

  policy = <<EOF
{
   "Version":"2012-10-17",
   "Statement":[{
      "Effect":"Allow",
      "Action":[
         "cloudhsm:*",
         "ec2:CreateNetworkInterface",
         "ec2:DescribeNetworkInterfaces",
         "ec2:DescribeNetworkInterfaceAttribute",
         "ec2:DetachNetworkInterface",
         "ec2:DeleteNetworkInterface",
         "ec2:CreateSecurityGroup",
         "ec2:AuthorizeSecurityGroupIngress",
         "ec2:AuthorizeSecurityGroupEgress",
         "ec2:RevokeSecurityGroupEgress",
         "ec2:DescribeSecurityGroups",
         "ec2:DeleteSecurityGroup",
         "ec2:CreateTags",
         "ec2:DescribeVpcs",
         "ec2:DescribeSubnets",
         "iam:CreateServiceLinkedRole",
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
         "dynamodb:DescribeTable",
         "dynamodb:CreateBackup",
         "dynamodb:RestoreTableFromBackup",
         "dynamodb:PutItem",
         "dynamodb:UpdateItem",
         "dynamodb:DeleteItem",
         "dynamodb:GetItem",
         "dynamodb:Query",
         "dynamodb:Scan",
         "dynamodb:BatchWriteItem",
         "dynamodb:DescribeBackup"
      ],
      "Resource":"*"
   }]
}
EOF
}

# Creates Role, referencing "vault-hsm-policy"
resource "aws_iam_role" "vault-hsm-role" {
  name = "${var.prefix}-vault-hsm-role"

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

# Attaches "vault-hsm-policy" to "vault-hsm-role"
resource "aws_iam_role_policy_attachment" "vault-hsm-policy-attach" {
  role       = aws_iam_role.vault-hsm-role.name
  policy_arn = aws_iam_policy.vault-hsm-policy.arn
}

resource "aws_iam_instance_profile" "vault-hsm-instance-profile" {
  name = "${var.prefix}-vault-hsm-instance-profile"
  role = aws_iam_role.vault-hsm-role.name
}