# Creates private key pair for EC2 SSH access
resource "tls_private_key" "vault" {
  algorithm = "RSA"
}

locals {
  private_key_filename = "${var.prefix}-ssh-key.pem"
}

resource "aws_key_pair" "vault" {
  key_name   = local.private_key_filename
  public_key = tls_private_key.vault.public_key_openssh

  provisioner "local-exec" { # Create "myKey.pem" to your computer!!
    command = <<-EOT
      echo '${tls_private_key.vault.private_key_pem}' > ./privateKey.pem
      chmod 400 ./privateKey.pem
    EOT
  }
}