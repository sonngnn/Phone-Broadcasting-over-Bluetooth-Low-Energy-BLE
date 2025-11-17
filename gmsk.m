function modulated_signal = gmsk(input_bits, sps, Tb)
    % GMSK Modulation
    %
    % Inputs:
    %   - input_bits: Vecteur de bits à moduler (0 ou 1).
    %   - sps: Nombre d'échantillons par symbole (samples per symbol).
    %   - Tb: Durée d'un bit (en secondes).
    %
    % Output:
    %   - modulated_signal: Signal modulé GMSK (complexe).

    % Vérification des entrées
    if nargin < 3
        error('Usage: modulated_signal = gmsk(input_bits, sps, Tb)');
    end

    % Modulation GMSK
    modulated_signal = GMSK_modulation(input_bits, sps, Tb);
end