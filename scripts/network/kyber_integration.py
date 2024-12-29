import logging
import oqs

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("PostQuantum")

def generate_kyber_keys():
    """
    Generates public and private keys using Kyber.
    """
    kem = oqs.KeyEncapsulation("Kyber512")
    public_key = kem.generate_keypair()
    logger.info(f"Kyber public key: {public_key}")
    return kem, public_key

def encapsulate_key(kem, public_key):
    """
    Encapsulates a key using the public key.
    """
    ciphertext, shared_secret = kem.encap_secret(public_key)
    logger.info(f"Encapsulated ciphertext: {ciphertext}")
    logger.info(f"Shared secret: {shared_secret}")
    return ciphertext, shared_secret

def decapsulate_key(kem, private_key, ciphertext):
    """
    Decapsulates the shared secret using the private key.
    """
    shared_secret = kem.decap_secret(ciphertext)
    logger.info(f"Decapsulated shared secret: {shared_secret}")
    return shared_secret

def establish_pqc_connection():
    """
    Establishes a post-quantum secure connection using Kyber.
    """
    kem, public_key = generate_kyber_keys()
    # Simulate sending the public key to the server
    logger.info("Public key sent to server.")

    # Simulate receiving encapsulated key from the server
    ciphertext, shared_secret_server = encapsulate_key(kem, public_key)
    logger.info("Ciphertext received from server.")

    # Decapsulate the shared secret
    shared_secret_client = decapsulate_key(kem, kem.export_secret_key(), ciphertext)

    if shared_secret_client == shared_secret_server:
        logger.info("Shared secrets match! Connection is secure.")
    else:
        logger.error("Shared secrets do not match. Connection is insecure.")

if __name__ == "__main__":
    establish_pqc_connection()
