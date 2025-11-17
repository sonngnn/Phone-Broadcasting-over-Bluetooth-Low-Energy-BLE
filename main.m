%% Projet BLE avec ISS

clear
clc
close all

%% Emetteur

% Fichier à envoyer

% Déterminer extension pour savoir quel algorithme utiliser

% Si .mp4 ...

% On obtient flux binaire avec les algos utilisés

% Savoir si on utilise legacy ou extended advertising

% Si Extended : 

% Fragmentation en paquets de 253 octets (les 2 octets restants : 2 bits 
% pour le type des données envoyées et le reste pour numérotation du paquet)

% Si legacy (SMS...):

% Fragmentation en 31 octets

% Pour chaque paquet, ajouter header avec adresse MAC de l'émetteur

% Ajoute CRC, faire Whitening

% Choisir quel FEC est choisi (S=2, S=8 ou pas de FEC) en fonction du débit
% voulu. 

% Ajouter préambule et access address 

% Faire modulation GMSK

% Envoyer sur fréquence porteuse choisie (frequency hopping si nécessaire)


%% Canal
% Simuler canal : bruit + décalage temporel

%% Recépteur

% Ecoute sur fréquence porteuse désignée

% Réception paquet par paquet

% Démodulation GMSK

% Accès préambule, access address

% Enlever redondance lié à FEC (information dans préambule, détermination
% de S avec un champ dans le header indiquant quel S est 

% Déblanchissement du signal

% Check CRC si correct

% Avec data -> voir type de donnée, n° du paquet (savoir si il y a eu de la
% perte) 

% Recomposer paquets

% Avec le flux binaire complet -> faire algo inverse pour trouver
% image/voix envoyé initialement


%% Paramètres de la modulation GMSK
BT = 0.5; % produit bandwidth-tyime

Rb = 1e6; % débit binaire (1 Mbit/s)

Fs = 10e6; % fréquence d'échantillonnage

Ts = 1/Fs; % période d'échantillonnage

Tb = 1/Rb; % durée d'un bit

t = 0:Ts:100*Tb-Ts; % temps pour 100 bits

% fréquence porteuse
fc = 2.4e9; % typique pour le BLE

%% Emetteur

% génération d'un flux binaire aléatoire
data = randi([0 1], 1, 1000);




% modulation GMSK
signal_gmsk = gmsk_modulation(data, BT, Rb, Fs, fc);

%% Canal (simulation)
% ajout de bruit et décalage temporel

% SNR = 20; % rapport signal sur bruit (en dB)


% signal_gmsk_noisy = awgn(signal_gmsk, SNR, 'measured'); % ajout de bruit

%% Récepteur

% démodulation GMSK
received_data = gmsk_demodulation(signal_gmsk, BT, Rb, Fs, fc); %remplacer avec signal_gmsk_noisy

% vérification des données reçues
disp("Données transmises :");
disp(data);
disp("Données reçues :");
disp(received_data);

figure,
plot(pwelch(signal_gmsk,256,32,256))
%% Fonction de modulation GMSK
function signal_gmsk = gmsk_modulation(data, BT, Rb, Fs, fc)
    % Paramètres
    Tb = 1/Rb; % Durée d'un bit
    t = 0:1/Fs:length(data)*Tb-1/Fs; % Temps d'échantillonnage
    
    % 1. Conversion du flux binaire en signal NRZ (-1 et 1)
    symbols = 2 * data - 1;

    % 2. Intégration du signal NRZ
    integrated_signal = cumsum(symbols) * Tb;

    % 3. Filtrage Gaussien
    sigma = sqrt(log(2)) / (2 * pi * BT); % Écart-type du filtre
    gauss_filter = exp(-t.^2 / (2 * sigma^2)); % Réponse impulsionnelle
    gauss_filter = gauss_filter / sum(gauss_filter); % Normalisation
    filtered_phase = conv(integrated_signal, gauss_filter, 'same'); % Filtrage

    % Correction : Interpolation de `filtered_phase` pour correspondre à `t`
    phase_interp = interp1(linspace(0, max(t), length(filtered_phase)), filtered_phase, t, 'linear', 'extrap');

    % 4. Modulation en quadrature
    I = cos(2 * pi * fc * t) .* cos(2 * pi * phase_interp);
    Q = -sin(2 * pi * fc * t) .* sin(2 * pi * phase_interp);

    % 5. Somme des composantes pour générer le signal modulé
    signal_gmsk = I + Q;
end


%% Fonction de démodulation GMSK
function received_data = gmsk_demodulation(signal_gmsk, BT, Rb, Fs, fc)
    % paramètres
    Tb = 1/Rb; % durée d'un bit

    t = 0:1/Fs:length(signal_gmsk)/Fs-1/Fs; % Temps pour le signal reçu



    
    % démodulation en quadrature
    I = signal_gmsk .* cos(2 * pi * fc * t); % composante in-phase

    Q = signal_gmsk .* sin(2 * pi * fc * t); % composante quadrature


    
    % filtrage passe-bas (simplifié)
    I_filtered = lowpass(I, Rb/2, Fs);

    Q_filtered = lowpass(Q, Rb/2, Fs);


    
    % estimation de la phase
    % phase_est = atan2(I_filtered, Q_filtered);
    phase_est = atan2(Q_filtered, I_filtered);



    
    % calcul de la dérivée de la phase (fréquence instantanée)
    % freq_est = diff(phase_est) / (2 * pi * Tb);
    freq_est = gradient(phase_est) / (2 * pi * Tb);


    
    % détection des symboles
    symbols_est = sign(freq_est(1:Tb*Fs:end)); % échantillonnage aux instants de décision


    
    % conversion des symboles en bits
    received_data = (symbols_est + 1) / 2;
end