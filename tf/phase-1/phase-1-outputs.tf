output "aws_vpc_id" {
  value = aws_vpc.vault.id
}

output "vault_ip" {
  value = aws_eip.vault.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.vault.endpoint
}

output "vault_ent_ip" {
  value = aws_eip.vault-ent.public_ip
}