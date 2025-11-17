function [bits, sampled] = GMSK_demodulation(signal, sps)
    % Phase instantanée
    phase = unwrap(angle(signal));
    
    % Dérivée de phase
    dphase = diff(phase);
    dphase = [dphase; dphase(end)];  % pour garder la même longueur

    % Sous-échantillonnage : 1 échantillon au centre de chaque symbole
    %offset = floor(sps / 2);  % centre du symbole
    sampled = dphase(1 : sps : end);

    % Décision binaire
    bits = sampled > 0;
end
