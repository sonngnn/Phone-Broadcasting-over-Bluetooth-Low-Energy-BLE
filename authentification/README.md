# Exemple d’Authentification

Ce dépôt montre comment ajouter une **authentification basée sur Ed25519** à un système de diffusion BLE (Bluetooth Low Energy), par exemple pour envoyer des alertes depuis un drone (ou un simulateur ISS) vers plusieurs appareils récepteurs. À la fin, vous disposerez d’un exemple Python fonctionnel qui :

- Génère une paire de clés Ed25519 (clé privée + clé publique)
- Signe chaque message complet une seule fois
- Fragmentation et diffusion via des trames BLE
- Réassemble et vérifie sur n’importe quel récepteur grâce à la clé publique

---

## ⚙️ Prérequis

- **Python 3.8+**
- Bibliothèques système (Debian/Ubuntu) :
  ```bash
  sudo apt update
  sudo apt install -y python3-pip build-essential libffi-dev libsodium-dev
  ```
- **PyNaCl** (Ed25519) :
  ```bash
  pip3 install pynacl
  ```

---

## 📁 Structure du dépôt

```text
ble_auth_app/
├── auth/                  # Module d’authentification
│   └── ed25519_auth.py    # génération, chargement, signature, vérification
├── tx/                    # Simulation de l’émetteur
│   └── ble_transmitter.py
├── rx/                    # Simulation du récepteur
│   └── ble_receiver.py
├── main.py                # Exemple de fonctionnement de bout en bout
└── requirements.txt       # Dépendances Python
```

---

## 🔑 1. Génération des clés (une seule fois)

Avant le vol, générez une paire de clés Ed25519 :

```bash
# créer le dossier keys
mkdir -p keys

# script de génération
touch generate_keys.py && cat << 'EOF' > generate_keys.py
import os
import nacl.signing

os.makedirs("keys", exist_ok=True)

# génération de la paire
sk = nacl.signing.SigningKey.generate()
vk = sk.verify_key

# écriture des fichiers
with open("keys/signing_key.pem","wb") as f:
    f.write(sk.encode())
with open("keys/verify_key.pem","wb") as f:
    f.write(vk.encode())
print("✅ Clés générées dans le dossier keys/")
EOF

# exécution
python3 generate_keys.py
```

- **`keys/signing_key.pem`** (privée) → à copier uniquement sur le drone.
- **`keys/verify_key.pem`** (publique) → à inclure dans chaque application/récepteur.

---

## 🛠 2. Module d’authentification

**Fichier :** `auth/ed25519_auth.py`

Ce module fournit :

- `generate_keypair()`
- `load_signing_key(path)` et `load_verify_key(path)`
- `sign_message(msg, sk)` → signature de 64 octets
- `verify_message(msg, sig, vk)` → booléen

Il crée automatiquement le dossier `keys/` si besoin et ajoute les clés privées à `.gitignore`.

---

## 🚁 3. Intégration de l’émetteur

**Fichier :** `tx/ble_transmitter.py`

1. **Charger** la clé privée :
   ```python
   sk = load_signing_key('keys/signing_key.pem')
   ```
2. **Signer** le message complet `M` une seule fois :
   ```python
   sig = sign_message(M, sk)
   ```
3. **Diffuser** :
   - Envoyer une **trame méta** contenant `msg_id`, `total_frags` et `sig`.
   - Fragmenter `M` en morceaux de ≤ 217 octets et envoyer chaque fragment avec un en-tête (`msg_id`, `frag_idx`, fragment).

---

## 📱 4. Intégration du récepteur

**Fichier :** `rx/ble_receiver.py`

1. **Charger** la clé publique :
   ```python
   vk = load_verify_key('keys/verify_key.pem')
   ```
2. **Recevoir** les trames et stocker selon `msg_id` :
   - Sur trame méta : relever `total_frags` et conserver `sig`.
   - Sur trames de données : stocker chaque fragment dans `buffers[msg_id]`.
3. **Réassembler** lorsque tous les fragments sont reçus :
   ```python
   M_rebuilt = b''.join(chunks[i] for i in range(total_frags))
   ```
4. **Vérifier** :
   ```python
   if verify_message(M_rebuilt, sig, vk):
       deliver(M_rebuilt)
   else:
       drop(msg_id)
   ```

---

## 🧩 5. Protection contre la relecture (optionnelle)

Pour prévenir les attaques par relecture :

1. Ajouter un **compteur monotone** ou **horodatage** (8 octets) au début de `M` avant signature.
2. Conserver en mémoire le dernier compteur vu pour chaque `msg_id` et rejeter les anciens.

---

## ✅ 6. Démonstration rapide

Lancez l’exemple :

```bash
pip3 install -r requirements.txt
python3 main.py
```

Vous devriez voir :

```
✅ Clés générées...
🚀 Émetteur : envoi de la trame (...)
📥 Récepteur : trame reçue (...)
✅ Signature valide. Payload : b'...'
```


---

*En résumé, nous protégeons chaque alerte en signant le message complet une fois avec la clé privée du drone, en diffusant les fragments normalement, puis en vérifiant sur chaque appareil avec la clé publique pour garantir intégrité et authentification.*

