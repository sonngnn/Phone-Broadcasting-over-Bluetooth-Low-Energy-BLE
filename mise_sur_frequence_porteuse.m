function signal_rf = mise_sur_frequence_porteuse(signal_gmsk, fc, Fs)
    % Mise sur fréquence porteuse
    %
    % Inputs:
    %   - signal_gmsk: Signal modulé GMSK en bande de base (vecteur complexe).
    %   - fc: Fréquence porteuse (en Hz).
    %   - Fs: Fréquence d'échantillonnage (en Hz).
    %
    % Output:
    %   - signal_rf: Signal modulé en bande passante (vecteur réel).

    % Vérification des entrées
    if nargin < 3
        error('Usage: signal_rf = mise_sur_frequence_porteuse(signal_gmsk, fc, Fs)');
    end

    % Vecteur temps
    t = (0:length(signal_gmsk)-1) / Fs;

    % Génération de la porteuse
    carrier = cos(2 * pi * fc * t);

    % Mise sur fréquence porteuse (modulation en amplitude)
    signal_rf = real(signal_gmsk) .* carrier;
end