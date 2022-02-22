### VAULT NODE 2 ###

resource "aws_eip" "vault-hsm-2" {
  instance = aws_instance.vault-hsm-2.id
  vpc      = true
}

resource "aws_eip_association" "vault-hsm-2" {
  instance_id   = aws_instance.vault-hsm-2.id
  allocation_id = aws_eip.vault-hsm-2.id
}

resource "aws_instance" "vault-hsm-2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.vault.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.vault-a.id
  vpc_security_group_ids      = [aws_security_group.vault.id, aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.vault-hsm-instance-profile.name

  tags = {
    Name          = "${var.prefix}-vault-hsm-2-instance"
  }
}

resource "null_resource" "configure-vault-hsm-2" {
  depends_on = [aws_eip_association.vault-hsm-2]

  # triggers = {
  #   build_number = timestamp()
  # }

  provisioner "file" {
    source      = "./files/vault_hsm/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.vault.private_key_pem
      host        = aws_eip.vault-hsm-2.public_ip
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
      host        = aws_eip.vault-hsm-2.public_ip
    }
  }
}


### VAULT NODE 3 ###

resource "aws_eip" "vault-hsm-3" {
  instance = aws_instance.vault-hsm-3.id
  vpc      = true
}

resource "aws_eip_association" "vault-hsm-3" {
  instance_id   = aws_instance.vault-hsm-3.id
  allocation_id = aws_eip.vault-hsm-3.id
}

resource "aws_instance" "vault-hsm-3" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.vault.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.vault-a.id
  vpc_security_group_ids      = [aws_security_group.vault.id, aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.vault-hsm-instance-profile.name

  tags = {
    Name          = "${var.prefix}-vault-hsm-3-instance"
  }
}

resource "null_resource" "configure-vault-hsm-3" {
  depends_on = [aws_eip_association.vault-hsm-3]

  # triggers = {
  #   build_number = timestamp()
  # }

  provisioner "file" {
    source      = "./files/vault_hsm/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.vault.private_key_pem
      host        = aws_eip.vault-hsm-3.public_ip
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
      host        = aws_eip.vault-hsm-3.public_ip
    }
  }
}

