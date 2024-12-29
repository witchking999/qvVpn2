import logging
from Crypto.Cipher import AES
from src.network.post_quantum.kyber_integration import generate_kyber_keys, encapsulate_key, decapsulate_key

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("Quad9DNS")


def encrypt_dns_query(query, shared_secret):
    """
    Encrypts a DNS query using a shared secret.
    """
    cipher = AES.new(shared_secret[:16], AES.MODE_GCM)
    ciphertext, tag = cipher.encrypt_and_digest(query)
    return cipher.nonce, ciphertext, tag


def decrypt_dns_query(nonce, ciphertext, tag, shared_secret):
    """
    Decrypts a DNS query using a shared secret.
    """
    cipher = AES.new(shared_secret[:16], AES.MODE_GCM, nonce=nonce)
    plaintext = cipher.decrypt_and_verify(ciphertext, tag)
    return plaintext


def resolve_secure_dns_query(domain, shared_secret):
    """
    Resolves a domain securely using Quad9 with encrypted DNS queries.
    """
    query = f"Resolve {domain}".encode()
    nonce, ciphertext, tag = encrypt_dns_query(query, shared_secret)
    logger.info(f"Encrypted DNS query: {ciphertext}")

    # Simulate sending and receiving encrypted data
    logger.info("Simulating encrypted DNS query resolution...")
    received_plaintext = decrypt_dns_query(nonce, ciphertext, tag, shared_secret)
    logger.info(f"Decrypted DNS query result: {received_plaintext.decode()}")


if __name__ == "__main__":
    kem, public_key = generate_kyber_keys()
    logger.info("Generated Kyber keys for DNS encryption.")

    # Simulate key exchange
    ciphertext, shared_secret_encap = encapsulate_key(kem, public_key)
    shared_secret_decap = decapsulate_key(kem, kem.export_secret_key(), ciphertext)

    if shared_secret_encap == shared_secret_decap:
        logger.info("Shared secrets match. Proceeding with secure DNS resolution.")
        resolve_secure_dns_query("example.com", shared_secret_decap)
    else:
        logger.error("Key exchange failed. Cannot proceed with DNS resolution.")
