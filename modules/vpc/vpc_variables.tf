variable "address_space" {
  description = "The address space that is used by the virtual network. You can supply more than one address space. Changing this forces a new resource to be created."
  default     = "10.0.0.0/16"
}

variable "prefix" {
  description = "Prefix that will be added to all taggable resources"
  default = "prefix"
}