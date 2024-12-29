# Define common name for the certificate
variable "common_name" {
  description = "The common name for the certificate (e.g., solutionv.io)."
  type        = string
}

# DNS names for the certificate
variable "dns_names" {
  description = "List of DNS names for which the certificate will be valid."
  type        = list(string)
  default     = ["solutionv.io", "vault.solutionv.io", "localhost"]
}

# IP addresses for the certificate
variable "ip_addresses" {
  description = "List of IP addresses for which the certificate will be valid."
  type        = list(string)
  default     = ["127.0.0.1", "192.168.128.106", "192.168.128.80"]
}

# Certificate validity period in hours
variable "validity_period_hours" {
  description = "The number of hours after issuing that the certificate will become invalid."
  type        = number
  default     = 87600 # 10 years
}

# File paths for saving certificates
variable "ca_cert_path" {
  description = "Path to save the CA certificate file."
  type        = string
  default     = "/home/witchking999/qVvpn/v2/certs/ca.crt.pem"
}

variable "cert_path" {
  description = "Path to save the signed certificate file."
  type        = string
  default     = "/home/witchking999/qVvpn/v2/certs/vault.crt.pem"
}

variable "private_key_file_path" {
  description = "Path to save the private key file."
  type        = string
  default     = "/home/witchking999/qVvpn/v2/certs/vault.key.pem"
}

# Permissions for generated files
variable "file_permissions" {
  description = "Unix file permissions for the generated files (e.g., 0640)."
  type        = string
  default     = "0640"
}

# Private key algorithm and RSA bit size
variable "private_key_algorithm" {
  description = "The algorithm to use for the private key (e.g., RSA or ECDSA)."
  type        = string
  default     = "RSA"
}

variable "rsa_bits" {
  description = "The size of the RSA key in bits."
  type        = number
  default     = 4096
}
