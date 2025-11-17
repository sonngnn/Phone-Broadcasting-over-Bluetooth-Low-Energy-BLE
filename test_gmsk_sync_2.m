% test_gmsk_sync_fixed2.m
clear; clc; close all;

%% === PARAMÈTRES ===
coeffDesyncFreq = 0;   % 0 = pas d’offset freq, juste bruit
SNRdB           = 10;  % en dB
N               = 1000; % bits utiles
sps             = 8;   % échantillons/symbole
Tb              = 1;   % durée symbole
Fs              = sps/Tb;

%% === GÉNÉRATION BITSTREAM ===
preamble_bits = [0 1 0 1 0 1 0 1];
data_bits     = randi([0 1], N, 1);
tx_bits       = [preamble_bits.'; data_bits];

%% === MODULATION ===
tx = GMSK_modulation(tx_bits, sps, Tb);

%% === CANAL ===
tx_noisy = add_complex_noise(tx, SNRdB);
t        = (0:length(tx)-1)'/Fs;
tx_freq  = tx_noisy .* (exp(1i*2*pi*0.01*t).^coeffDesyncFreq);

%% === SYNCHRONISATION TEMPORELLE (conv 'valid') ===
tmpl     = GMSK_modulation(preamble_bits, sps, Tb);     % template
c_valid  = abs(conv(tx_freq, flipud(conj(tmpl)), 'valid'));
[peak, startIdx] = max(c_valid);
% startIdx est l’échantillon où commence le template
% on aligne sur frontière symbole
rem = mod(startIdx-1, sps);
if rem ~= 0, startIdx = startIdx + (sps - rem); end
fprintf('StartIdx = %d (corr peak = %.2f)\n', startIdx, peak);
aligned = tx_freq(startIdx : end);

%% === SYNCHRO FRÉQUENTIELLE/PHASE ===
% PLL PI ordre 2 sur aligned
off = aligned;
M  = 2;   Kp = 0.1;  Ki = 0.01;
Nsig = length(off);
theta = zeros(Nsig,1);
fi    = zeros(Nsig,1);
out   = zeros(size(off));
out(1) = off(1);
for k = 2:Nsig
    out(k) = off(k)*exp(-1i*theta(k-1));
    z   = out(k).^M; z = z/abs(z);
    err = imag(z*conj(out(k).^M));
    fi(k)    = fi(k-1) + Ki*err;
    theta(k) = theta(k-1) + Kp*err + fi(k);
end
corr_signal = out;

%% === DÉMODULATION ===
[rx_bits_all, ~] = GMSK_demodulation(corr_signal, sps);

% extraction bits
rx_preamble = rx_bits_all(1:8);
rx_data     = rx_bits_all(9 : 8+N);

%% === COMPARAISON ===
if length(rx_data) < N
    error('Rx length %d < expected %d', length(rx_data), N);
end
n_err = sum(rx_data ~= data_bits);
BER   = n_err / N;
fprintf('BER = %.4f (%d/%d)\n', BER, n_err, N);
fprintf('Preamble match: %s\n', mat2str(rx_preamble.' == preamble_bits));

%% === CONSTELLATION ===
sym_idx = 1:sps:length(corr_signal);
figure;
plot(real(corr_signal(sym_idx)), imag(corr_signal(sym_idx)), '.');
axis equal; grid on;
title('Constellation post-PLL');
xlabel('Re'); ylabel('Im');
