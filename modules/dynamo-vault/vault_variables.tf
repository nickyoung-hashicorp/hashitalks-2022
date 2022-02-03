variable "prefix" {
  description = "Prefix that will be added to all taggable resources"
  default = "prefix"
}

variable "vpc_id" {
  description = "ID of VPC in which to deploy resources"
  default = ""
}

variable "subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "Specifies the AWS instance type."
  default     = "t2.micro"
}