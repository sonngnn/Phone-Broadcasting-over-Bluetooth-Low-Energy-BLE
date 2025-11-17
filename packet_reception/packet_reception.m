clear;
close all;
clc;

%% Paramètres
default_CRC_init = '555555';
channel = 37;

%% Réception du signal BLE
% Supposons que 'signal_recu' est la trame reçue après conversion RF -> Baseband
signal_recu = load('testmodule.mat'); % Fonction hypothétique pour acquérir le signal
signal_recu2 = load('test5_w.mat');

% disp('Premiers 40 bits du signal recu :');
% disp(signal_recu.packets_modulated{1,1}(1:40));

packet_recu = signal_recu.packets_modulated{1,1};

%% Démodulation GMSK de BLE
sps = 8;

packets_modulated = GMSK_demodulation(packet_recu, sps);


%% Détection du préambule et synchronisation temporelle
% [t] = detect_preambule(packets_modulated); % Trouver le début
% packets_modulated = packets_modulated(t:end); % On garde à partir de la fin du préambule

% %% Détection du préambule et synchronisation temporelle
% [t] = detect_preambule(packets_modulated); % Retourne l'indice du début des données utiles
% packets_modulated = packets_modulated(t+1*8:end); % Retrait du préambule (8 bits)
% 
% %% Synchronisation fréquentielle
% packets_synchro_freq = synchro_freq(packets_modulated);
% 
% %% Retrait de l'Access Address
% packets_modulated = packets_synchro_freq(32+1:end); % Suppression de 32 bits d'Access Address


%% Dewhitening (Blanchiment inversé du signal)

dewhitened_data = dewhitening_ble(packets_modulated(41:end), channel);

%% Vérification du CRC

[is_valid, data_without_crc] = verify_crc(dewhitened_data, default_CRC_init);
if ~is_valid
    error('Erreur CRC : les données sont corrompues');
end

%% Extraction des données utiles (PDU - Protocol Data Unit)
pdu_data = extract_PDU(data_without_crc);

disp('Réception et traitement terminés avec succès.');
pdu = extract_PDU(data_without_crc);

disp('Header bits :');
disp(pdu.header_bits);

disp('Length bits :');
disp(pdu.length_bits);

disp('Payload bits :');
disp('AdvA :')
disp(pdu.advA);

%disp('AdvData (ad strcture) :');
%disp(pdu.ad_structure);

disp('Length ad structure (1o) :');
disp(pdu.length_ads);

disp('AdType (ad structure) 0xFF (1o) :');
disp(pdu.ad_type);

disp('Sigle :');
disp(pdu.sigle);

disp('Data utiles :');
disp(pdu.data);
