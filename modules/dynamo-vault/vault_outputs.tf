output "vault_ip" {
  value = "http://${aws_eip.vault.public_ip}"
}