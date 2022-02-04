### Variables ###

variable "table_name" {
  description = "The name of the Dynamo Table to create and use as a storage backend."
  default = "vault-backend"
}

variable "read_capacity" {
  description = "Sets the DynamoDB read capacity for storage backend"
  default     = 5
}

variable "write_capacity" {
  description = "Sets the DynamoDB write capacity for storage backend"
  default     = 5
}

### Resources ###

resource "aws_dynamodb_table" "vault_dynamo" {
  name           = var.table_name
  hash_key       = "Path"
  range_key      = "Key"
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity

  attribute {
    name = "Path"
    type = "S"
  }

  attribute {
    name = "Key"
    type = "S"
  }
}