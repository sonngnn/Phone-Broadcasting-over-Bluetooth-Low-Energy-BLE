import os
import nacl.signing
import nacl.exceptions

KEY_DIR = 'keys/'  # Dossier pour stocker les clés
os.makedirs(KEY_DIR, exist_ok=True)


def generate_keypair():
    """Génère une paire de clés Ed25519 et les enregistre dans keys/"""
    sk = nacl.signing.SigningKey.generate()
    vk = sk.verify_key
    # écriture de la clé privée
    with open(os.path.join(KEY_DIR, 'signing_key.pem'), 'wb') as f:
        f.write(sk.encode())
    # écriture de la clé publique
    with open(os.path.join(KEY_DIR, 'verify_key.pem'), 'wb') as f:
        f.write(vk.encode())
    print(f"✅ Clés générées dans {KEY_DIR}")
    return sk, vk


def load_signing_key(path=None):
    """Charge la clé privée depuis un fichier PEM"""
    path = path or os.path.join(KEY_DIR, 'signing_key.pem')
    return nacl.signing.SigningKey(open(path, 'rb').read())


def load_verify_key(path=None):
    """Charge la clé publique depuis un fichier PEM"""
    path = path or os.path.join(KEY_DIR, 'verify_key.pem')
    return nacl.signing.VerifyKey(open(path, 'rb').read())


def sign_message(message: bytes, sk: nacl.signing.SigningKey) -> bytes:
    """Retourne la signature (64 octets) pour le message donné"""
    signed = sk.sign(message)
    return signed.signature


def verify_message(message: bytes, signature: bytes, vk: nacl.signing.VerifyKey) -> bool:
    """Vérifie la signature; retourne True si valide, False sinon"""
    try:
        vk.verify(message, signature)
        return True
    except nacl.exceptions.BadSignatureError:
        return False