function preamble_modulated = gmsk_preamble(sps, Tb)
% gmsk_preamble - Génère un préambule GMSK basé sur 10101010
%
% Entrées :
%   - sps : Nombre d’échantillons par symbole
%   - Tb  : Durée d’un bit (en secondes)
%
% Sortie :
%   - preamble_modulated : préambule modulé GMSK (signal complexe)

    % Préambule binaire : alternance 1 et 0 sur 8 bits
    preamble_bits = [0 1 0 1 0 1 0 1];

    % Modulation GMSK de cette séquence
    preamble_modulated = gmsk(preamble_bits, sps, Tb);

end
