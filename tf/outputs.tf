output "rds_endpoint" {
  value = aws_db_instance.vault.endpoint
}

output "vault_ip" {
  value = aws_eip.vault.public_ip
}

output "vault_ent_ip" {
  value = aws_eip.vault-ent.public_ip
}

output "vault_hsm_ip" {
  value = aws_eip.vault-hsm.public_ip
}