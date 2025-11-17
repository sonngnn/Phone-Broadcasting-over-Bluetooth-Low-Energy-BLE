clear;
clc;
close all;
% === PARAMÈTRES ===
coeffDesyncFreq = 0; % Mettre à 0 pour tester seulement avec le bruit
SNRdB = 10;         % SNR pour l'ajout du bruit dans le canal

N = 1000;       % Nombre de bits
sps = 8;        % Échantillons par symbole
Tb = 1;         % Durée symbole

Fs = 1/Tb;      % Symobles/s
% === GÉNÉRATION DES BITS ===
bits = randi([0 1], N, 1);

% === MODULATION GMSK ===
tx = GMSK_modulation(bits, sps, Tb);

% === SIMULATION CANAL ===
%simulation rudimentaire, pas forcément adaptée à nos cas de transmission réels
[a,b] = size(tx); sigma=0.2;
% tx_noisy = tx + sigma * (randn(a,b)+1i*randn(a,b));

tx_noisy = add_complex_noise(tx,SNRdB); % revoir la fonction d'ajout du bruit


f_offset = 0.01;
t = (0:a-1)'/Fs; %time axis
tx_freq_async = tx_noisy .* (exp(1i * 2 * pi * f_offset * t).^coeffDesyncFreq);


tx_canal = tx_freq_async;
% === DEMODULATION GMSK ===
[rx_bits, sampled] = GMSK_demodulation(tx_canal, sps);

% === BER ====
% Eventuellement ajouter des courbes de TEB en fonction du SNR/ de la désynchro fréquentielle
TEB=length(nonzeros(rx_bits~=bits))/length(bits);
SNRdB_vector=-100:5:10;
TEB_vector = zeros(size(SNRdB_vector));
% *** Rajouter boucle pour le calcul du TEB ***


% === Affichages ===
% Pour afficher l'évolution des symboes après le canal
nSecs = 30; % secondes de vidéo
signalVideoAnalyzer0(tx_canal(1:min(length(tx_canal),24*nSecs)),1,"Visualisation du signal après canal",24)
% décommenter pour afficher

figure
plot(TEB_vector,SNRdB_vector)
title("SNR = f(TEB)")
xlabel("TEB")
ylabel("SNR (dB)")

testTx = tx_canal(1:1000);
phase = unwrap(angle(testTx));

figure
subplot(2,1,1)

plot(phase)
xlabel("échantillons")
ylabel("\phi_{signal reçu}")
subplot(2,1,2)
plot(diff(phase))
xlabel("échantillons")
ylabel("d/dt\phi_{signal reçu}")
sgtitle(sprintf("Visualisation du signal recu \nSNR = %2f dB, TEB: %2f",SNRdB,TEB));



%% Fonctions
function signalVideoAnalyzer0(signal, nPoints, title, fps)
anl = signal;
videoFileName = title + ".mp4";
videoWriter = VideoWriter(videoFileName, 'MPEG-4');
videoWriter.FrameRate = fps;
open(videoWriter);

nFrames = floor(length(anl) / nPoints);
cadre = max(abs(signal(:))) * [-1 1]; % Limits for the axes

% Create a single figure and hold on
figure;
hold on;
theta = linspace(0, 2*pi, 100);
r0 = 1;
x = r0 * cos(theta);
y = r0 * sin(theta);

% Creation of the video
for i = 0:nFrames-1
    % Clear the current axes
    cla;
plot(x, y, '-r', 'LineWidth', 1); % Plot the circle
    % Plot the current frame data
    plot(anl(i*nPoints + 1:(i + 1)*nPoints), "ob",MarkerSize=5);
    xlim(cadre);
    ylim(cadre);
    xlabel({'Re(signal)',sprintf('frame %d',i)});
    ylabel('Im(signal)');
    % title("")
    grid on;

    % Set the title for the current frame
    % title(['Frame ' num2str(i + 1)]);
    legend("Cercle de rayon 1","symbole")
    % Capture the frame
    frame = getframe(gcf);
    writeVideo(videoWriter, frame);
end

% Close the video writer
close(videoWriter);
end

function signal_bruite=add_complex_noise(signal,RSB) % Fonction à revoir, pas testée
h = signal(:);
L = length(h); % Length of the signal
RSB_lin=10^(RSB/10);
% Calculate power values
Ps = sum(abs(h.^2))/L; % Power of the original signal
b =  randn(L, 1)+1i*randn(L, 1); % BBGC de sigma =1
Pb = sum(abs(b.^2))/L; % Power of the noise (BBGC de sigma =1)
sigma = sqrt(Ps/(Pb*RSB_lin));
signal_bruite = sigma*b + h;

end

