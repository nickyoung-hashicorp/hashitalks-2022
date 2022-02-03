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
