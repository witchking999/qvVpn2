#!/bin/bash
# This script installs Vault and its dependencies.
# Tested on:
# - Ubuntu 16.04
# - Ubuntu 18.04
# - Amazon Linux 2

set -e

# Default configurations
readonly DEFAULT_INSTALL_PATH="/opt/vault"
readonly DEFAULT_VAULT_USER="vault"
readonly DEFAULT_SKIP_PACKAGE_UPDATE="false"
readonly DEFAULT_VAULT_VERSION="1.18.3"  # Latest version as of now

readonly DOWNLOAD_PACKAGE_PATH="/tmp/vault.zip"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SYSTEM_BIN_DIR="/usr/local/bin"
readonly SCRIPT_NAME="$(basename "$0")"

# Function to print usage information
function print_usage {
  echo
  echo "Usage: install-vault [OPTIONS]"
  echo
  echo "Options:"
  echo -e "  --version\t\tVault version to install (default: $DEFAULT_VAULT_VERSION)."
  echo -e "  --download-url\tURL to the Vault package (overrides --version)."
  echo -e "  --path\t\tInstallation path (default: $DEFAULT_INSTALL_PATH)."
  echo -e "  --user\t\tUser to own the Vault installation (default: $DEFAULT_VAULT_USER)."
  echo -e "  --skip-package-update\tSkip package updates (default: $DEFAULT_SKIP_PACKAGE_UPDATE)."
  echo
  echo "Example:"
  echo "  install-vault --version 1.18.3"
}

# Logging functions
function log {
  local level="$1"
  local message="$2"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  >&2 echo -e "${timestamp} [${level}] [${SCRIPT_NAME}] ${message}"
}

function log_info { log "INFO" "$1"; }
function log_warn { log "WARN" "$1"; }
function log_error { log "ERROR" "$1"; }

# Assertion functions
function assert_not_empty {
  local arg_name="$1"
  local arg_value="$2"
  if [[ -z "$arg_value" ]]; then
    log_error "The value for '$arg_name' cannot be empty"
    print_usage
    exit 1
  fi
}

function assert_either_or {
  local arg1_name="$1"
  local arg1_value="$2"
  local arg2_name="$3"
  local arg2_value="$4"
  if [[ -z "$arg1_value" && -z "$arg2_value" ]]; then
    log_error "Either '$arg1_name' or '$arg2_name' must be provided"
    print_usage
    exit 1
  fi
}

# Retry function for commands
function retry {
  local cmd="$1"
  local description="$2"
  for i in $(seq 1 5); do
    log_info "$description"
    output=$(eval "$cmd") && exit_status=0 || exit_status=$?
    log_info "$output"
    if [[ $exit_status -eq 0 ]]; then
      echo "$output"
      return
    fi
    log_warn "$description failed. Retrying in 10 seconds..."
    sleep 10
  done
  log_error "$description failed after 5 attempts."
  exit $exit_status
}

# Check for package managers
function has_yum { [[ -n "$(command -v yum)" ]]; }
function has_apt_get { [[ -n "$(command -v apt-get)" ]]; }

# Install necessary dependencies
function install_dependencies {
  local skip_package_update=$1
  log_info "Installing dependencies"
  if has_apt_get; then
    [[ "$skip_package_update" != "true" ]] && sudo apt-get update -y
    sudo apt-get install -y curl unzip jq libcap2-bin
  elif has_yum; then
    [[ "$skip_package_update" != "true" ]] && sudo yum update -y
    sudo yum install -y curl unzip jq
  else
    log_error "Unsupported package manager. Install dependencies manually."
    exit 1
  fi
}

# Check if a user exists
function user_exists {
  local username="$1"
  id "$username" >/dev/null 2>&1
}

# Create a system user for Vault
function create_vault_user {
  local username="$1"
  if user_exists "$username"; then
    log_info "User $username already exists. Skipping creation."
  else
    log_info "Creating user named $username"
    sudo useradd --system "$username"
  fi
}

# Create installation directories
function create_vault_install_paths {
  local path="$1"
  local username="$2"
  log_info "Creating installation directories at $path"
  sudo mkdir -p "$path/bin" "$path/config" "$path/data" "$path/tls" "$path/scripts"
  sudo chmod 755 "$path" "$path/bin" "$path/data"
  log_info "Setting ownership of $path to $username"
  sudo chown -R "$username:$username" "$path"
}

# Download the Vault binary
function fetch_binary {
  local version="$1"
  local download_url="$2"
  if [[ -z "$download_url" && -n "$version" ]];  then
    download_url="https://releases.hashicorp.com/vault/${version}/vault_${version}_linux_amd64.zip"
  fi
  retry \
    "curl -o '$DOWNLOAD_PACKAGE_PATH' '$download_url' --location --silent --fail --show-error" \
    "Downloading Vault from $download_url"
}

# Install the Vault binary
function install_binary {
  local install_path="$1"
  local username="$2"
  local bin_dir="$install_path/bin"
  local vault_dest_path="$bin_dir/vault"
  unzip -d /tmp "$DOWNLOAD_PACKAGE_PATH"
  log_info "Moving Vault binary to $vault_dest_path"
  sudo mv "/tmp/vault" "$vault_dest_path"
  sudo chown "$username:$username" "$vault_dest_path"
  sudo chmod a+x "$vault_dest_path"
  local symlink_path="$SYSTEM_BIN_DIR/vault"
  if [[ -f "$symlink_path" ]]; then
    log_info "Symlink $symlink_path already exists. Skipping."
  else
    log_info "Creating symlink at $symlink_path"
    sudo ln -s "$vault_dest_path" "$symlink_path"
  fi
  log_info "Vault binary installed successfully"
}

# Configure mlock
function configure_mlock {
  log_info "Granting Vault mlock permissions"
  sudo setcap cap_ipc_lock=+ep /opt/vault/bin/vault
}

# Main installation function
function install {
  local version="$DEFAULT_VAULT_VERSION"
  local download_url=""
  local path="$DEFAULT_INSTALL_PATH"
  local user="$DEFAULT_VAULT_USER"
  local skip_package_update="$DEFAULT_SKIP_PACKAGE_UPDATE"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --version) version="$2"; shift ;;
      --download-url) download_url="$2"; shift ;;
      --path) path="$2"; shift ;;
      --user) user="$2"; shift ;;
      --skip-package-update) skip_package_update="true" ;;
      --help) print_usage; exit 0 ;;
      *) log_error "Unknown argument: $1"; print_usage; exit 1 ;;
    esac
    shift
  done

  assert_either_or "--version" "$version" "--download-url" "$download_url"
  assert_not_empty "--path" "$path"
  assert_not_empty "--user" "$user"

  log_info "Starting Vault installation"
  install_dependencies "$skip_package_update"
  create_vault_user "$user"
  create_vault_install_paths "$path" "$user"
  fetch_binary "$version" "$download_url"
  install_binary "$path" "$user"
  configure_mlock

  log_info "Vault installation complete!"
}

install "$@"
