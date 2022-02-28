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
      "Effect": "Allow",
      "Resource": [ "arn:aws:dynamodb:*:*:table/*" ]
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