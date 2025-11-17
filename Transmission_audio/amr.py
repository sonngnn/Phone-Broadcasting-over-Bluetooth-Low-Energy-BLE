# -*- coding: utf-8 -*-
"""
Created on Fri Mar 21 15:21:43 2025

@author: oubar
"""

import numpy as np
import sounddevice as sd
import soundfile as sf
import subprocess
import os

def file_to_bitstream(filename):
    """
    Conversion d'un fichier en flux de bits.
    Ouvre le fichier en mode binaire, lit son contenu et retourne un vecteur
    numpy d'octets décomposés en bits (MSB en premier).
    """
    with open(filename, 'rb') as f:
        data = np.frombuffer(f.read(), dtype=np.uint8)
    # np.unpackbits retourne les bits dans l'ordre du bit le plus significatif au moins
    bitstream = np.unpackbits(data)
    return bitstream

def bitstream_to_file(bitstream, filename):
    """
    Reconstruction d'un fichier à partir d'un flux de bits.
    Vérifie que la longueur du flux est un multiple de 8, recompose les octets
    puis écrit le fichier en mode binaire.
    """
    if len(bitstream) % 8 != 0:
        raise ValueError("La longueur du flux de bits n'est pas un multiple de 8.")
    # Recomposer les octets à partir des bits
    bytes_array = np.packbits(bitstream)
    with open(filename, 'wb') as f:
        f.write(bytes_array.tobytes())

def calculate_compression_ratio(original_file, compressed_file):
    """
    Calcule et affiche le rapport de compression entre le fichier original et le fichier compressé.
    """
    original_size = os.path.getsize(original_file)
    compressed_size = os.path.getsize(compressed_file)
    ratio = original_size / compressed_size
    print(f"\nTaille originale : {original_size} octets")
    print(f"Taille compressée : {compressed_size} octets")
    print(f"Rapport de compression : {ratio:.2f}x")

# --- Enregistrement et Compression ---
if __name__ == '__main__':
    fs = 8000       # Fréquence d'échantillonnage (8 kHz pour la voix)
    duration = 7    # Durée de l'enregistrement en secondes
    wav_file = 'audio_input.wav'
    
    # Capture du son avec le micro
    print("Enregistrement...")
    # sd.rec() enregistre 'duration*fs' échantillons; channels=1 pour mono, dtype='int16'
    audio_data = sd.rec(int(duration * fs), samplerate=fs, channels=1, dtype='int16')
    sd.wait()  # Attendre la fin de l'enregistrement
    # Sauvegarde en WAV (PCM 16 bits)
    sf.write(wav_file, audio_data, fs, subtype='PCM_16')
    print("Enregistrement terminé. Fichier WAV sauvegardé.")

    # Compression WAV en MP3 avec FFmpeg
    mp3_file = 'audio_output.mp3'
    subprocess.run(['ffmpeg', '-y', '-i', wav_file, '-b:a', '128k', mp3_file])
    print("\nCompression WAV en MP3 terminée.")
    calculate_compression_ratio(wav_file, mp3_file)

    # Compression WAV en AMR avec FFmpeg
    amr_file = 'audio_output.amr'
    subprocess.run(['ffmpeg', '-y', '-i', wav_file, '-ar', '8000', '-ac', '1', '-ab', '4.75k', amr_file])
    print("\nCompression WAV en AMR terminée.")
    calculate_compression_ratio(wav_file, amr_file)

    # --- Conversion en flux de bits (Simulation envoi par BLE) ---
    # Conversion du fichier AMR en flux de bits
    bitstream = file_to_bitstream(amr_file)
    print("\nConversion du fichier AMR en flux de bits terminée.")

    # Simulation de l'envoi par BLE :
    # On suppose que le flux de bits envoyé est intégralement reçu sans erreur.
    received_bitstream = bitstream
    print("Réception du flux de bits terminée.")

    # Reconstruction du fichier AMR à partir du flux de bits reçu
    reconstructed_file = 'audio_reconstructed.amr'
    bitstream_to_file(received_bitstream, reconstructed_file)
    print("Reconstruction du fichier à partir du flux de bits terminée.")

    # --- Décompression et Lecture ---
    # Conversion du fichier AMR reconstruit en WAV avec FFmpeg
    wav_converted_file = 'audio_output_converted.wav'
    subprocess.run(['ffmpeg', '-y', '-i', reconstructed_file, wav_converted_file])

    # Lire le fichier WAV reconstruit
    audio_data_rec, fs_rec = sf.read(wav_converted_file)
    
    # Lecture du son
    #sd.play(audio_data_rec, fs_rec)
    #sd.wait()

    # Affichage d'informations sur le fichier audio reconstruit
    print(f"\nFichier décompressé : {wav_converted_file}")
    print(f"Fréquence d'échantillonnage : {fs_rec} Hz")
    print(f"Nombre d'échantillons : {len(audio_data_rec)}")
    print(f"Durée : {len(audio_data_rec) / fs_rec:.2f} secondes")

    # Nettoyage des fichiers temporaires
    os.remove(wav_file)
    os.remove(wav_converted_file)
    print("Fichiers temporaires supprimés.")
