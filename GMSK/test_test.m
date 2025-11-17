%% File: test_gmsk_full.m
% Simulation complet GMSK avec synchronisation temporelle et fréquentielle
clear; clc; close all;

% === PARAMÈTRES ===
N         = 1000;     % nombre de bits
sps       = 8;        % échantillons par symbole
Tb        = 1;        % durée symbole
max_delay = 20;       % max décalage temporel (échantillons)
df        = 200;      % offset fréquentiel à simuler (Hz)
Kp        = 0.1; Ki   = 0.01; % paramètres PLL

% Fréquence d'échantillonnage
Fs = sps/Tb;

% === GÉNÉRATION DES BITS ===
bits = randi([0 1], N, 1);

% === SÉQUENCE DE SYNCHRO CONNUE ===
preamble = [0 1 0 1 0 1 0 1]';        % 8 bits alternés
advA_bi  = [0 1 0 1 0 1 0 1 1 1 0 1 1 1 0 1 0 0 1 1 0 0 1 1 1 0 1 1 1 0 1 1 0 1 1 1 0 1 1 1 1 1 1 1 1 1 1 1]'; % 48 bits
sync_bits = [preamble; advA_bi];         % colonne de 56 bits

% === MODULATION GMSK ===
tx = GMSK_modulation(bits, sps, Tb);

% === SIMULATION DÉCALAGE TEMPOREL ===
delay = randi([-max_delay, max_delay]);
if delay > 0
    rx_temp = [zeros(delay,1); tx];
    rx_temp = rx_temp(1:length(tx));
elseif delay < 0
    rx_temp = [tx(-delay+1:end); zeros(-delay,1)];
else
    rx_temp = tx;
end
fprintf('Décalage temporel appliqué : %d échantillons\n', delay);

% === SYNCHRO TEMPOREL ===
[rx_aligned, est_delay] = synchronisation_temporelle(rx_temp, sync_bits, sps, Tb);
fprintf('Décalage estimé      : %d échantillons\n', est_delay);

% === SIMULATION DÉCALAGE FRÉQUENTIEL ===
t = (0:length(rx_aligned)-1)'/Fs;
rx_freq = rx_aligned .* exp(1j*2*pi*df*t);
fprintf('Offset fréquentiel appliqué : %d Hz\n', df);

% === SYNCHRO FRÉQUENTIELLE ===
[rx_corrected, df_est] = synchronisation_frequentielle(rx_freq, sync_bits, sps, Tb, Fs, Kp, Ki);
fprintf('Offset estimé            : %.2f Hz\n', df_est);

% === DÉMODULATION GMSK ===
[rx_bits, ~] = GMSK_demodulation(rx_corrected, sps);

% === CALCUL BER ===
nber = sum(rx_bits ~= bits)/N;
fprintf('BER final (sans bruit AWGN) : %.4f\n', nber);

% === AFFICHAGE CONSTELLATION ===
hd = 2*rx_bits - 1;
figure;
scatter(hd, zeros(size(hd)), 15, 'filled');
xlim([-1.5 1.5]); ylim([-0.5 0.5]);
title('Constellation GMSK après synchronisation');
xlabel('Valeur'); set(gca,'YTick',[]); grid on;

%% ===== FONCTIONS LOCALES =====

function gfilter = GMSK_gaussian_filter(T, sps)
    t = (-1.5*T : T/sps : 1.5*T);
    BT = 0.5;
    h = (BT*sqrt((2*pi)/log(2))) .* exp(-((2*pi^2*BT^2).*t.^2)./log(2));
    gfilter = h ./ sqrt(sum(h));
end

function tx = GMSK_modulation(bits, sps, Tb)
    data = 2*bits - 1;
    rect = upsample(data, sps);
    gauss = GMSK_gaussian_filter(Tb, sps);
    m_filt = conv(rect, gauss, 'same');
    phase = cumsum(m_filt);
    tx = cos(phase) + 1j*sin(phase);
end

function [bits, sampled] = GMSK_demodulation(rx, sps)
    phase = unwrap(angle(rx));
    dphase = diff(phase); dphase = [dphase; dphase(end)];
    sampled = dphase(1:sps:end);
    bits = sampled > 0;
end

function [aligned, est_lag] = synchronisation_temporelle(rx, sync_bits, sps, Tb)
    ref = GMSK_modulation(sync_bits, sps, Tb);
    [c, lags] = xcorr(rx, ref);
    [~, idx] = max(abs(c));
    est_lag = lags(idx);
    if est_lag > 0
        aligned = rx(est_lag+1:end);
        aligned = [aligned; zeros(est_lag,1)];
    elseif est_lag < 0
        aligned = [zeros(-est_lag,1); rx(1:end+est_lag)];
    else
        aligned = rx;
    end
    aligned = aligned(1:length(rx));
end

function [out, df_est] = synchronisation_frequentielle(rx, sync_bits, sps, Tb, Fs, Kp, Ki)
    % Estimation grossière via préambule
    ref = GMSK_modulation(sync_bits, sps, Tb);
    L = length(ref);
    seg = rx(1:L);
    phase_ref = unwrap(angle(ref));
    phase_rx  = unwrap(angle(seg));
    t_seg = (0:L-1)'/Fs;
    p = polyfit(t_seg, phase_rx - phase_ref, 1);
    df_est = p(1)/(2*pi);
    rx_corr = rx .* exp(-1j*2*pi*df_est*((0:length(rx)-1)'/Fs));

    % PLL (boucle de Costas)
    N = length(rx_corr);
    theta = zeros(N,1);
    omega = zeros(N,1);
    out   = zeros(N,1);
    for n = 2:N
        corr = exp(-1j*theta(n-1));
        y    = rx_corr(n)*corr;
        out(n) = y;
        prev = rx_corr(n-1)*exp(-1j*theta(n-1));
        e = angle(y*conj(prev));
        omega(n) = omega(n-1) + Ki*e;
        theta(n) = theta(n-1) + Kp*e + omega(n);
    end
end
