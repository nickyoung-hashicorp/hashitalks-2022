output "vpc" {
    value = module.vpc.aws_vpc_id
}

output "vault_ip" {
    value = module.vault-dynamodb.vault_ip
}