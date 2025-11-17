% test_gmsk_sync.m
clear; clc; close all;

%% === PARAMÈTRES ===
coeffDesyncFreq = 0;    % 0 pour ne tester que le bruit
SNRdB           = 1;    % en dB
N               = 1000; % nombre de bits utiles
sps             = 8;    % échantillons par symbole
Tb              = 1;    % durée symbole
Fs              = sps/Tb;

% préambule et bits à transmettre
preamble_bits = [1 0 1 0 1 0 1 0];
data_bits     = randi([0 1], N, 1);

% on concatène préambule + données
tx_bits = [preamble_bits.'; data_bits];
assert(length(tx_bits)==8+N, 'tx_bits length mismatch');

%% === MODULATION ===
tx = GMSK_modulation(tx_bits, sps, Tb);
assert(length(tx)==length(tx_bits)*sps, 'TX length mismatch');

%% === CANAL : bruit + offset de fréquence ===
tx_noisy = add_complex_noise(tx, SNRdB);
[a,~]    = size(tx_noisy);
t        = (0:a-1)'/Fs;
tx_freq  = tx_noisy .* (exp(1i*2*pi*0.01*t).^coeffDesyncFreq);

%% === SYNCHRO TEMPORELLE ===
tmpl     = GMSK_modulation(preamble_bits, sps, Tb);
startIdx = synchro_temp(tx_freq, tmpl, sps);
aligned  = tx_freq(startIdx : end);

assert(~isempty(aligned), 'Signal after temporal sync is empty');

%% === SYNCHRO FRÉQUENTIELLE/PHASE ===
corr_signal = synchro_freq(aligned, sps);
assert(length(corr_signal)==length(aligned), 'PLL changed signal length');

%% === DÉMODULATION ===
[rx_bits, sampled] = GMSK_demodulation(corr_signal, sps);

% on doit avoir au moins 8+N bits
assert(length(rx_bits) >= 8+N, ...
    'Trop peu de bits reçus (%d < %d)', length(rx_bits), 8+N);

% extraction des N bits de données
rx_data = rx_bits(8+1 : 8+N);

%% === BILAN ===
BER = sum(rx_data~=data_bits) / N;
fprintf('BER = %.4f pour SNR=%d dB, coeffDesyncFreq=%d, bits traités=%d\n', ...
        BER, SNRdB, coeffDesyncFreq, N);
