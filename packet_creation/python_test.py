import numpy as np

def generate_modulated_signal(packets_modulated, multiple_send, number_packets, interval_time, sps, data_rate):
    wait_time = int(interval_time * sps * data_rate)
    wait_vector = np.zeros(wait_time, dtype=np.int8)  # Création d'un vecteur de "wait" rempli de zéros
    global final_env_formatIQ_synthetic
    final_env_formatIQ_synthetic = []  # Liste pour stocker le signal final modifié
    
    for nb_repetition in range(multiple_send):
        for idx_packets in range(number_packets):
            # Extraction de la forme d'onde du paquet modulaire
            global tx_waveform_doppler
            tx_waveform_doppler = packets_modulated[idx_packets*multiple_send + nb_repetition].T
            
            # Extraire les composantes I et Q de la forme d'onde
            env_I_synthetic = np.real(tx_waveform_doppler).T
            env_Q_synthetic = np.imag(tx_waveform_doppler).T
            
            # Combinaison des composantes I et Q
            global mat_env_formatIQ_synthetic
            mat_env_formatIQ_synthetic = np.vstack((env_I_synthetic, env_Q_synthetic))
            
            # Mise à l'échelle des valeurs (multiplier par 64 pour la résolution 8 bits)
            global env_formatIQ_synthetic
            env_formatIQ_synthetic = (64 * mat_env_formatIQ_synthetic.T.flatten()).astype(np.float64)
            
            # Ajout à la liste finale
            
            final_env_formatIQ_synthetic.extend(env_formatIQ_synthetic)
            final_env_formatIQ_synthetic.extend(wait_vector)  # Ajouter le vecteur d'attente
    
    # Génération du nom du fichier de sortie
    filename = f'./binary_file/BLE_frame_1.bin'
    
    # Enregistrement des données dans un fichier binaire
    with open(filename, 'wb') as file:
        np.array(final_env_formatIQ_synthetic, dtype=np.int8).tofile(file)


def GMSK_gaussian_filter(T, sps):
    t = np.linspace(-1.5 * T, 1.5 * T, int(3 * T * sps) + 1)
    BT = 0.5
    h = (BT * np.sqrt((2 * np.pi) / np.log(2))) * np.exp(-((2 * np.pi**2) * (BT**2) * t**2) / np.log(2))
    K = np.pi / 2 / np.sum(h)
    gfilter = K * h
    return gfilter

def GMSK_modulation(signal, sps, Tb):
    global m_filtered2
    signal = 2 * signal - 1
    rect = np.zeros(len(signal) * sps)
    rect[::sps] = signal
    gaussfilter = GMSK_gaussian_filter(Tb, sps)
    m_filtered = np.convolve(rect, gaussfilter, mode='same')
    m_filtered1 = np.cumsum(m_filtered)
    m_filtered2 = np.cos(m_filtered1) + 1j * np.sin(m_filtered1)
    return m_filtered2

def convert_file(file_to_send):
    with open(file_to_send, 'rb') as file:
        byte_stream = np.frombuffer(file.read(), dtype=np.uint8)
    
    bitstream = np.unpackbits(byte_stream).reshape(-1, 8)  # Convertir en bits avec 'right-msb'
    bitstream = bitstream.T.flatten()  # Mise à plat en colonne comme en MATLAB
    
    return bitstream

def fragmentation(bitstream):
    legacy_length_max = 227 * 8
    legacy_length = legacy_length_max - 8 * 8
    
    # Utilisation de numpy pour découper en fragments
    fragments = np.array_split(bitstream, np.arange(legacy_length, len(bitstream), legacy_length))
    
    return fragments

import numpy as np

def add_crc(pdu, crc_init):
    """
    Ajoute un CRC Bluetooth à un PDU.

    Args:
        pdu (list or np.array): Liste ou tableau de bits (0 ou 1) représentant la PDU.
        crc_init (str): Valeur d'initialisation du CRC sous forme hexadécimale (ex: '555555').

    Returns:
        np.array: Vecteur de bits correspondant à la PDU concaténée avec les 24 bits du CRC.
    """
    CRC_POLYNOMIAL = 0x100065B  # x^24 + x^10 + x^9 + x^6 + x^4 + x^3 + x + 1

    # Convertir la chaîne hexadécimale crc_init en entier 24 bits
    crc_value = int(crc_init, 16) & 0xFFFFFF  # Masque pour garantir 24 bits

    # Calcul du CRC bit par bit
    for bit in pdu:
        msb = (crc_value >> 23) & 1  # Récupère le MSB (bit 23)
        crc_value = (crc_value << 1) & 0xFFFFFF  # Décalage à gauche + masque 24 bits
        if bit ^ msb:
            crc_value ^= CRC_POLYNOMIAL

    # Extraction des 24 bits CRC (du bit 23 au bit 0)
    crc_bits = np.array([(crc_value >> i) & 1 for i in range(23, -1, -1)], dtype=int)

    # Concaténation PDU + CRC
    return np.concatenate((np.array(pdu, dtype=int), crc_bits))


def hex_cell_to_binary(hex_list):
    """
    Convert a list of single-character hexadecimal strings
    into a binary list with MSB on the right (global reversal).
    """
    binary_stream = []

    for hex_char in hex_list:
        # Convert hex char to int
        dec_value = int(hex_char, 16)
        # Convert to 4-bit binary string, left-msb
        bin_string = format(dec_value, '04b')
        # Add bits as integers
        binary_stream.extend([int(bit) for bit in bin_string])

    # Reverse the entire bitstream (like fliplr)
    binary_stream.reverse()

    return binary_stream

import numpy as np

def whitening_ble(bits, channel):
    """
    Applique le whitening BLE à une séquence de bits via un LFSR.

    Args:
        bits (list or np.array): Séquence de bits (0 ou 1).
        channel (int): Index du canal BLE (0 à 39).

    Returns:
        np.array: Séquence whitened, même taille que `bits`.
    """
    # 1. Définition du polynôme x^7 + x^4 + 1 (on exclut x^7 car il n'est pas utilisé dans le XOR direct)
    polynomial = np.zeros(8, dtype=int)
    polynomial[[0, 4, 7]] = 1  # Correspond à x^0, x^4, x^7
    working_poly = polynomial[:7]  # équivalent à polynomial(1:7) en MATLAB

    # 2. Initialisation du LFSR : MSB = 1 suivi des 6 bits du canal
    ch_bin = [int(b) for b in format(channel, '06b')]
    state = np.array([1] + ch_bin, dtype=int)

    # 3. Boucle de whitening
    bits = np.array(bits, dtype=int)
    out_array = np.zeros_like(bits)
    for i in range(len(bits)):
        out_bit = state[-1]
        out_array[i] = bits[i] ^ out_bit

        # Décalage vers la droite avec insertion d’un 0 à gauche
        state = np.insert(state[:-1], 0, 0)

        # Feedback si out_bit == 1
        state ^= out_bit * working_poly

    return out_array


def create_packet_legacy_mobile(fragments, advA_bi, multiple_send):
    primary_channel_index = 37
    preamble = np.array([0, 1, 0, 1, 0, 1, 0, 1])
    access_address_hex = ['8', 'E', '8', '9', 'B', 'E', 'D', '6']
    access_address_bi = hex_cell_to_binary(access_address_hex)
    default_CRC_init = '555555'
    nb_different_packet = len(fragments)
    
    data_type = [0, 1]
    header_legacy = np.array([0, 0, 0, 0, 0, 1, 1, 0])
    data_type_mobile = np.repeat(data_type, 4)
    SIGa = 0x4512  # Tableau de valeurs à convertir en bits
    # Convertir en tableau de 2 octets
    two_bytes = np.array([SIGa], dtype=np.uint16).view(np.uint8)  # Conversion en 2 octets
    # Convertir les octets en bits et inverser pour little-endian
    SIG_bi = np.unpackbits(two_bytes)[::-1]
    full_packets = []
    for fragment_number in range(1, nb_different_packet + 1):
        fragment_number_bi = np.unpackbits(np.array([fragment_number], dtype=np.uint8))[::-1]
        fragment_number_max_bi = np.unpackbits(np.array([nb_different_packet], dtype=np.uint8))[::-1]
        adData = np.concatenate((data_type_mobile, fragment_number_bi, fragment_number_max_bi, fragments[fragment_number - 1]))
        user_data_length = len(adData) // 8 + 3
        user_data_length_bi = np.unpackbits(np.array([user_data_length], dtype=np.uint8))[::-1]
        user_data_type_bi = np.unpackbits(np.array([0xFF], dtype=np.uint8))[::-1]
        advData = np.concatenate([user_data_length_bi, user_data_type_bi , SIG_bi, adData])
        payload = np.concatenate((advA_bi, advData))

        length_payl = len(payload)

        # Choisir un type plus large si besoin (ici uint16 pour avoir 16 bits)
        payload_len_bytes = np.array([length_payl / 8], dtype=np.uint)

        # Décomposer en bits en little endian
        length_payload = np.unpackbits(payload_len_bytes.view(np.uint8), bitorder='little')[0:8]
        pdu = np.concatenate((header_legacy, length_payload, payload))
        pdu_crc = add_crc(pdu, default_CRC_init)
        pdu_whitened = whitening_ble(pdu_crc, primary_channel_index)
        full_packet = np.concatenate((preamble, access_address_bi, pdu_whitened))
        global pdu_test
        pdu_test = np.concatenate((preamble, access_address_bi, pdu_crc))
        full_packets.append(full_packet)
    
    return full_packets


data_rate = 1e6
sps = 8
Tb = 1

file_to_send = "../transmission_image/image_test.jpg"
advA_bi = np.array([0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
multiple_send = 3
interval_time = 0.002


bitstream = convert_file(file_to_send)
fragments = fragmentation(bitstream)
packets = create_packet_legacy_mobile(fragments, advA_bi, multiple_send)

modulated_packet_all = []

number_packets = len(packets)

for idx in range(number_packets):
    modulated_packet = GMSK_modulation(packets[idx], sps, Tb)
    if idx == 0:
        len_max = len(modulated_packet)
    if (len(modulated_packet) != len_max):
        add_vector = np.zeros(len_max-len(modulated_packet))
        modulated_packet = np.concatenate([modulated_packet,add_vector])
    
    #temp_packet = modulated_packet
    for nb_sent in range(multiple_send):
        modulated_packet_all.append(modulated_packet)
    
    
generate_modulated_signal(modulated_packet_all, multiple_send, number_packets, interval_time, sps, data_rate)
    





