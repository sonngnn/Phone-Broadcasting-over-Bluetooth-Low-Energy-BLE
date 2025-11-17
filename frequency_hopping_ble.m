function frequency_hopping_ble(signal_rf, Fs, hop_sequence, hop_interval)
    % Frequency Hopping pour BLE
    %
    % Inputs:
    %   - signal_rf: Signal modulé en bande passante (vecteur réel).
    %   - Fs: Fréquence d'échantillonnage (en Hz).
    %   - hop_sequence: Séquence de saut de fréquence (liste des canaux).
    %   - hop_interval: Intervalle de temps entre les sauts (en secondes).

    % Vérification des entrées
    if nargin < 4
        error('Usage: frequency_hopping_ble(signal_rf, Fs, hop_sequence, hop_interval)');
    end

    % Fréquences des canaux BLE (en Hz)
    ble_channels = [
        2.402e9, 2.426e9, 2.480e9, ... % Canaux d'advertising (37, 38, 39)
        2.404e9, 2.406e9, 2.408e9, ... % Canaux de données (0 à 36)
        2.410e9, 2.412e9, 2.414e9, ...
        2.416e9, 2.418e9, 2.420e9, ...
        2.422e9, 2.424e9, 2.428e9, ...
        2.430e9, 2.432e9, 2.434e9, ...
        2.436e9, 2.438e9, 2.440e9, ...
        2.442e9, 2.444e9, 2.446e9, ...
        2.448e9, 2.450e9, 2.452e9, ...
        2.454e9, 2.456e9, 2.458e9, ...
        2.460e9, 2.462e9, 2.464e9, ...
        2.466e9, 2.468e9, 2.470e9, ...
        2.472e9, 2.474e9, 2.476e9, ...
        2.478e9
    ];

    % Boucle de saut de fréquence
    for i = 1:length(hop_sequence)
        % Sélection du canal actuel
        channel_index = hop_sequence(i);
        fc = ble_channels(channel_index + 1); % +1 car MATLAB indexe à partir de 1

        % Mise sur fréquence porteuse
        t = (0:length(signal_rf)-1) / Fs;
        carrier = cos(2 * pi * fc * t);
        signal_hopping = signal_rf .* carrier;

        % Envoi du signal sur le canal actuel (simulé)
        disp(['Envoi du signal sur le canal ', num2str(channel_index), ' (', num2str(fc/1e9), ' GHz)']);

        % Attente de l'intervalle de saut
        pause(hop_interval);
    end
end