import struct
from auth.ed25519_auth import load_signing_key, sign_message

MTU_DATA_SIZE = 217  # octets de données utiles par fragment

class BLETransmitter:
    """
    Transmetteur BLE simulé qui signe un message complet
    puis envoie le flux en trames metadata + data.
    """
    def __init__(self, key_path: str, receiver):
        self.sk = load_signing_key(key_path)
        self.receiver = receiver
        self._next_msg_id = 1

    def send_message(self, message: bytes):
        """Signe puis fragmente le message et envoie via BLE"""
        msg_id = self._next_msg_id
        self._next_msg_id += 1

        # signature unique pour tout le message
        signature = sign_message(message, self.sk)
        # découpe en fragments
        chunks = [message[i:i+MTU_DATA_SIZE] for i in range(0, len(message), MTU_DATA_SIZE)]
        total_frags = len(chunks)

        # 1) trame METADATA : type=0, msg_id, total_frags, signature
        meta_frame = struct.pack('>B I H', 0, msg_id, total_frags) + signature
        print(f"🚀 Transmetteur: envoi METADATA (msg={msg_id}, frags={total_frags})")
        self.receiver.receive_frame(meta_frame)

        # 2) trames DATA : type=1, msg_id, frag_idx, chunk
        for idx, chunk in enumerate(chunks):
            data_frame = struct.pack('>B I H', 1, msg_id, idx) + chunk
            print(f"🚀 Transmetteur: envoi DATA fragment {idx+1}/{total_frags} ({len(chunk)} octets)")
            self.receiver.receive_frame(data_frame)
