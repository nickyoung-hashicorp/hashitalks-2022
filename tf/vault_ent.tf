resource "aws_eip" "vault-ent" {
  instance = aws_instance.vault-ent.id
  vpc      = true
}

resource "aws_eip_association" "vault-ent" {
  instance_id   = aws_instance.vault-ent.id
  allocation_id = aws_eip.vault-ent.id
}

resource "aws_instance" "vault-ent" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.vault.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.vault-a.id
  vpc_security_group_ids      = [aws_security_group.vault.id]
  iam_instance_profile        = aws_iam_instance_profile.vault-dynamodb-instance-profile.name

  tags = {
    Name = "${var.prefix}-vault-ent-instance"
  }
}

resource "null_resource" "configure-vault-ent" {
  depends_on = [aws_eip_association.vault-ent]

  # triggers = {
  #   build_number = timestamp()
  # }

  provisioner "file" {
    source      = "./files/vault_ent/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.vault.private_key_pem
      host        = aws_eip.vault-ent.public_ip
    }
  }

    provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.vault.private_key_pem
      host        = aws_eip.vault-ent.public_ip
    }
  }
}