% test_gmsk_sync.m
clear; clc; close all;

%% === PARAMÈTRES ===
coeffDesyncFreq = 0;  % 0 = pas d’offset fréquentiel (juste le bruit)
SNRdB           = 10; % SNR canal en dB
N               = 1000; % bits utiles
sps             = 8;
Tb              = 1;
Fs              = sps/Tb;

%% === GÉNÉRATION DES BITS ===
preamble_bits = [0 1 0 1 0 1 0 1];   % 8 bits préambule
data_bits     = randi([0 1], N, 1);

% on injecte le préambule devant les données
tx_bits = [preamble_bits.'; data_bits];

%% === MODULATION GMSK ===
tx = GMSK_modulation(tx_bits, sps, Tb);

%% === SIMULATION DU CANAL ===
tx_noisy = add_complex_noise(tx, SNRdB);
t        = (0:length(tx)-1)'/Fs;
tx_freq  = tx_noisy .* (exp(1i*2*pi*0.01*t).^coeffDesyncFreq);

%% === SYNCHRO TEMPORELLE ===
tmpl     = GMSK_modulation(preamble_bits, sps, Tb);
startIdx = synchro_temp(tx_freq, tmpl, sps);
fprintf("Début préambule détecté à l'échantillon %d\n", startIdx);

% on garde la portion à partir du préambule
aligned = tx_freq(startIdx:end);

%% === SYNCHRO FRÉQUENTIELLE / PLL ===
corr_signal = synchro_freq(aligned);

%% === DÉMODULATION ===
[rx_bits_all, ~] = GMSK_demodulation(corr_signal, sps);

% on sait que les 8 premiers bits sont le préambule
rx_preamble = rx_bits_all(1:8);
rx_data     = rx_bits_all(9:8+N);

%% === COMPARAISON ===
n_errors = sum(rx_data ~= data_bits);
BER      = n_errors / N;
fprintf("BER = %.4f (%d erreurs sur %d bits)\n", BER, n_errors, N);

% vérif préambule
fprintf("Preamble OK? %s\n", mat2str(rx_preamble == preamble_bits'));

%% === AFFICHAGE CONSTELLATION ===
% un point par symbole sur la portion corrigée
idx_sym = 1:sps:length(corr_signal);
figure;
plot(real(corr_signal(idx_sym)), imag(corr_signal(idx_sym)), '.');
axis equal; grid on;
title('Constellation après PLL');
xlabel('Re'); ylabel('Im');
