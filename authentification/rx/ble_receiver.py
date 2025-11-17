import struct
from auth.ed25519_auth import load_verify_key, verify_message

class BLEReceiver:
    """
    Récepteur BLE simulé qui réassemble les fragments,
    vérifie la signature globale et affiche le payload.
    """
    def __init__(self, key_path: str):
        self.vk = load_verify_key(key_path)
        self.buffers = {}  # msg_id -> { total_frags, signature, chunks }

    def receive_frame(self, frame: bytes):
        """Gère l'arrivée d'une trame BLE (metadata ou data)"""
        # entête commun: 1 octet type, 4 octets msg_id
        frame_type, msg_id = struct.unpack_from('>B I', frame, 0)

        if frame_type == 0:
            # METADATA
            total_frags = struct.unpack_from('>H', frame, 5)[0]
            signature   = frame[7:7+64]
            self.buffers[msg_id] = {
                'total_frags': total_frags,
                'signature':   signature,
                'chunks':      {}
            }
            print(f"📥 Récepteur: METADATA reçu (msg={msg_id}, frags={total_frags})")

        elif frame_type == 1:
            # DATA fragment
            frag_idx = struct.unpack_from('>H', frame, 5)[0]
            chunk    = frame[7:]
            buf = self.buffers.get(msg_id)
            if not buf:
                print(f"⚠️ Récepteur: fragment reçu sans metadata (msg={msg_id})")
                return
            buf['chunks'][frag_idx] = chunk
            print(f"📥 Récepteur: DATA reçu (msg={msg_id}, frag={frag_idx+1})")

            # si tous les fragments reçus, réassembler
            if len(buf['chunks']) == buf['total_frags']:
                assembled = b''.join(buf['chunks'][i] for i in range(buf['total_frags']))
                # vérification finale
                if verify_message(assembled, buf['signature'], self.vk):
                    print(f"✅ Signature valide pour msg={msg_id}. Payload: {assembled}")
                else:
                    print(f"❌ Signature invalide pour msg={msg_id}!")
                # libération du buffer
                del self.buffers[msg_id]
        else:
            print("⚠️ Récepteur: type de trame inconnu")