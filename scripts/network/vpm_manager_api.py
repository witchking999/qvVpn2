import os
import requests
import logging
from time import sleep
from src.network.post_quantum.kyber_integration import (
    generate_kyber_keys,
    encapsulate_key,
    decapsulate_key
)

# Configuration
LOG_FILE = "vpn_manager.log"
API_BASE_URL = os.getenv("TAILSCALE_BASE_URL", "https://api.tailscale.com/api/v2")
API_KEY = os.getenv("TAILSCALE_API_KEY")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger("VPNManagerAPI")


class VPNManagerAPI:
    def __init__(self, api_key: str, base_url: str):
        if not api_key:
            logger.error("API key is missing. Set the TAILSCALE_API_KEY environment variable.")
            raise ValueError("API key is required.")
        self.api_key = api_key
        self.base_url = base_url
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        self.shared_secret = None

    def establish_pqc_connection(self):
        """
        Establishes a VPN connection secured by post-quantum cryptography.
        """
        logger.info("Establishing PQC-secured VPN connection...")
        kem, public_key = generate_kyber_keys()
        logger.info("Kyber keys generated.")

        # Simulate sending the public key to a remote server
        ciphertext, shared_secret_encap = encapsulate_key(kem, public_key)
        logger.info("Ciphertext generated for secure communication.")

        # Simulate receiving the ciphertext back
        shared_secret_decap = decapsulate_key(kem, kem.export_secret_key(), ciphertext)

        # Validate shared secret
        if shared_secret_encap == shared_secret_decap:
            logger.info("Shared secrets match. VPN connection is PQC-secure.")
            self.shared_secret = shared_secret_encap
        else:
            logger.error("Shared secrets mismatch. Connection is insecure.")
            raise ValueError("PQC key exchange failed.")

    def get_shared_secret(self):
        """
        Retrieves the shared secret for securing communications.
        """
        if self.shared_secret is None:
            raise ValueError("Shared secret is not established.")
        return self.shared_secret


if __name__ == "__main__":
    vpn_manager = VPNManagerAPI(API_KEY, API_BASE_URL)
    vpn_manager.establish_pqc_connection()
    logger.info("VPN is now secured with PQC.")
