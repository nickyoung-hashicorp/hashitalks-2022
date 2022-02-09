resource "aws_eip" "vault-hsm" {
  instance = aws_instance.vault-hsm.id
  vpc      = true
}

resource "aws_eip_association" "vault-hsm" {
  instance_id   = aws_instance.vault-hsm.id
  allocation_id = aws_eip.vault-hsm.id
}

resource "aws_instance" "vault-hsm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.vault.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.vault-a.id
  vpc_security_group_ids      = [aws_security_group.vault.id, aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.security_group_id]

  tags = {
    Name          = "${var.prefix}-vault-hsm-instance"
  }
}

resource "null_resource" "configure-vault-hsm" {
  depends_on = [aws_eip_association.vault-hsm]

  triggers = {
    build_number = timestamp()
  }

  provisioner "file" {
    source      = "./files/vault_hsm/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.vault.private_key_pem
      host        = aws_eip.vault-hsm.public_ip
    }
  }

    provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config",
      "sudo apt update -y",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.vault.private_key_pem
      host        = aws_eip.vault-hsm.public_ip
    }
  }
}

# Provision CloudHSM
resource "aws_cloudhsm_v2_cluster" "cloudhsm_v2_cluster" {
  hsm_type   = "hsm1.medium"
  subnet_ids = [aws_subnet.vault-a.id]

  tags = {
    Name = "${var.prefix}-vault-cloudhsm"
  }
}

resource "aws_cloudhsm_v2_hsm" "cloudhsm_v2_hsm" {
  cluster_id        = aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.cluster_id
  subnet_id = aws_subnet.vault-a.id
}