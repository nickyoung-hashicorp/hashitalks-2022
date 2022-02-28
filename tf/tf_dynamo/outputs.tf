output "vault_dynamo_1" {
  value = aws_eip.vault_1.public_ip
}

output "vault_dynamo_2" {
  value = aws_eip.vault_2.public_ip
}
