%% Enregistrement et Compression
fs = 8000;       % Fréquence d'échantillonnage (8 kHz pour la voix)
duration = 10;    % Durée de l'enregistrement (secondes)

% Capture du son avec un micro
fprintf('Enregistrement...\n');
recObj = audiorecorder(fs, 16, 2);  % 16 bits, mono
recordblocking(recObj, duration);  % Enregistrement pendant 7 secondes
audio_data = getaudiodata(recObj, 'int16');  % Récupération des données audio

% Sauvegarde en WAV (PCM 16 bits)
wav_file = 'audio_input.wav';
audiowrite(wav_file, audio_data, fs);
fprintf('Enregistrement terminé. Fichier WAV sauvegardé.\n');
wav_compressed_file = 'audio_compressed.wav';
system(['ffmpeg -y -i ', wav_file, ' -c:a adpcm_ima_wav ', wav_compressed_file]);
% Nom du fichier de sortie en AAC (.m4a)
aac_file = 'audio_output.m4a';

% Conversion WAV → AAC (encodage en AAC dans un conteneur M4A)
system(['ffmpeg -y -i ', wav_compressed_file, ' -c:a aac -b:a 128k ', aac_file]);

fprintf('\nCompression en AAC (.m4a) terminée.\n');


% Compression WAV en MP3 avec FFmpeg
mp3_file = 'audio_output.mp3';
system(['ffmpeg -y -i ', wav_file, ' -b:a 128k ', mp3_file]);
fprintf('\nCompression WAV en MP3 terminée.\n');
calculate_compression_ratio(wav_file, mp3_file);

% Compression WAV en AMR avec FFmpeg
amr_file = 'audio_output.amr';
system(['ffmpeg -y -i ', wav_file, ' -ar 8000 -ac 1 -ab 7.4k ', amr_file]);
fprintf('\nCompression WAV en AMR terminée.\n');
calculate_compression_ratio(wav_file, amr_file);

%% Conversion en flux de bits (Simulation envoi par BLE)
% Conversion du fichier AMR en flux de bits
bitstream = file_to_bitstream(amr_file);
fprintf('\nConversion du fichier AMR en flux de bits terminée.\n');
save('bitstream.mat', 'bitstream');

% Simulation de l'envoi par BLE :
% On suppose que le flux de bits envoyé est intégralement reçu sans erreur.
received_bitstream = bitstream;
fprintf('Réception du flux de bits terminée.\n');

% Reconstruction du fichier AMR à partir du flux de bits reçu
reconstructed_file = 'audio_reconstructed.amr';
bitstream_to_file(received_bitstream, reconstructed_file);
fprintf('Reconstruction du fichier à partir du flux de bits terminée.\n');

%% Décompression et Lecture
% Conversion du fichier AMR reconstruit en WAV avec FFmpeg
wav_converted_file = 'audio_output_converted.wav';
system(['ffmpeg -y -i ', reconstructed_file, ' ', wav_converted_file]);

% Lire le fichier WAV reconstruit
[audio_data_rec, fs_rec] = audioread(wav_converted_file);

% Lecture du son
%sound(audio_data_rec, fs_rec);

% Affichage d'informations sur le fichier audio reconstruit
fprintf('\nFichier décompressé : %s\n', wav_converted_file);
fprintf('Fréquence d''échantillonnage : %d Hz\n', fs_rec);
fprintf('Nombre d''échantillons : %d\n', length(audio_data_rec));
fprintf('Durée : %.2f secondes\n', length(audio_data_rec) / fs_rec);

% Nettoyage des fichiers temporaires
delete(wav_file);
delete(wav_converted_file);
fprintf('Fichiers temporaires supprimés.\n');
