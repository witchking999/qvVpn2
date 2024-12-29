# ---------------------------------------------------------------------------------------------------------------------
#  CREATE A CA CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "ca" {
  algorithm = var.private_key_algorithm

  # If ECDSA, use the specified curve
  ecdsa_curve = var.private_key_algorithm == "ECDSA" ? var.private_key_ecdsa_curve : null

  # If RSA, use the specified bit size
  rsa_bits = var.private_key_algorithm == "RSA" ? var.private_key_rsa_bits : null
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem   = tls_private_key.ca.private_key_pem
  is_ca_certificate = true

  validity_period_hours = var.validity_period_hours
  allowed_uses          = var.ca_allowed_uses

  subject {
    common_name  = var.ca_common_name
    organization = var.organization_name
  }

  # Store the CA public key in a file.
  provisioner "local-exec" {
    command = "echo '${tls_self_signed_cert.ca.cert_pem}' > '${var.ca_public_key_file_path}' && chmod ${var.permissions} '${var.ca_public_key_file_path}' && chown ${var.owner} '${var.ca_public_key_file_path}'"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A TLS CERTIFICATE SIGNED USING THE CA CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "cert" {
  algorithm = var.private_key_algorithm

  # If ECDSA, use the specified curve
  ecdsa_curve = var.private_key_algorithm == "ECDSA" ? var.private_key_ecdsa_curve : null

  # If RSA, use the specified bit size
  rsa_bits = var.private_key_algorithm == "RSA" ? var.private_key_rsa_bits : null

  # Store the certificate's private key in a file.
  provisioner "local-exec" {
    command = "echo '${tls_private_key.cert.private_key_pem}' > '${var.private_key_file_path}' && chmod ${var.permissions} '${var.private_key_file_path}' && chown ${var.owner} '${var.private_key_file_path}'"
  }
}

resource "tls_cert_request" "cert" {
  private_key_pem = tls_private_key.cert.private_key_pem

  dns_names    = var.dns_names
  ip_addresses = var.ip_addresses

  subject {
    common_name  = var.common_name
    organization = var.organization_name
  }
}

resource "tls_locally_signed_cert" "cert" {
  cert_request_pem = tls_cert_request.cert.cert_request_pem

  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = var.validity_period_hours
  allowed_uses          = var.allowed_uses

  # Store the certificate's public key in a file.
  provisioner "local-exec" {
    command = "echo '${tls_locally_signed_cert.cert.cert_pem}' > '${var.public_key_file_path}' && chmod ${var.permissions} '${var.public_key_file_path}' && chown ${var.owner} '${var.public_key_file_path}'"
  }
}
