resource "aws_dynamodb_table" "vault_dynamo_1" {
  name           = "dynamo-1"
  hash_key       = "Path"
  range_key      = "Key"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "Path"
    type = "S"
  }

  attribute {
    name = "Key"
    type = "S"
  }
}