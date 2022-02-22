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

output "vault_hsm_ip_2" {
  value = aws_eip.vault-hsm-2.public_ip
}

output "vault_hsm_ip_3" {
  value = aws_eip.vault-hsm-3.public_ip
}

output "hsm_cluster_id" {
  value = aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.cluster_id
}