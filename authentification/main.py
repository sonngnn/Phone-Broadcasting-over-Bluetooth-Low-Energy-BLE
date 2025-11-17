import os
from auth.ed25519_auth import generate_keypair
from tx.ble_transmitter import BLETransmitter
from rx.ble_receiver import BLEReceiver


def main():
    # génération des clés si nécessaire
    os.makedirs('keys', exist_ok=True)
    if not os.path.exists('keys/signing_key.pem'):
        generate_keypair()

    # initialisation du récepteur & émetteur
    receiver    = BLEReceiver(key_path='keys/verify_key.pem')
    transmitter = BLETransmitter(key_path='keys/signing_key.pem', receiver=receiver)

    # exemple de payload volumineux
    payload = (b"ALERTE_INONDATION_" + b"X" * 500)
    print(f"\n--- Envoi du payload de taille {len(payload)} octets ---")
    transmitter.send_message(payload)

if __name__ == '__main__':
    main()

