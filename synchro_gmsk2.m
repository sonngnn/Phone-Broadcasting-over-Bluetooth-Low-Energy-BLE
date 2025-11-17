function [delay, corr_val] = synchro_gmsk2(rx_signal, preamble_gmsk)
    % synchro_gmsk2: Synchronisation d'un signal GMSK par dérivation de phase
    %
    % Cette fonction synchronise un signal GMSK reçu en utilisant une approche
    % différentielle. Elle extrait la phase du signal reçu, réalise un unwrap,
    % calcule sa dérivée, et effectue une corrélation avec la dérivée de la
    % phase du préambule connu (sous forme GMSK modulée). Le pic de corrélation
    % permet d'estimer le décalage temporel du préambule dans le signal reçu.
    %
    % Inputs:
    %   - rx_signal: Signal reçu (vecteur complexe)
    %   - preamble_gmsk: Préambule connu sous forme de signal GMSK modulé (vecteur complexe)
    %
    % Outputs:
    %   - delay: Décalage temporel estimé (en nombre d'échantillons) indiquant
    %            la position de début du préambule dans rx_signal
    %   - corr_val: Vecteur de la corrélation (pour diagnostic ou visualisation)
    %
    % Exemple d'utilisation:
    %   [delay, corr_val] = synchro_gmsk2(rx_signal, preamble_gmsk);
    
    % Vérification des entrées
    if nargin < 2
        error('Usage: [delay, corr_val] = synchro_gmsk2(rx_signal, preamble_gmsk)');
    end
    
    %% Extraction et traitement de la phase
    % Extraction de la phase et déroulement (unwrap) pour éviter les sauts de 2pi
    phase_rx = unwrap(angle(rx_signal));
    phase_ref = unwrap(angle(preamble_gmsk));
    
    % Calcul de la dérivée de la phase (différence entre échantillons successifs)
    dphase_rx = diff(phase_rx);
    dphase_ref = diff(phase_ref);
    
    %% Corrélation différentielle
    % La corrélation de la dérivée du préambule (référence) avec celle du signal reçu
    % permet d'identifier l'alignement optimal. On utilise ici une convolution
    % avec la version inversée (et conjuguée) de dphase_ref.
    corr_val = conv(dphase_rx, fliplr(conj(dphase_ref)), 'full');
    
    % Recherche du pic de corrélation
    [~, idx_max] = max(abs(corr_val));
    
    %% Estimation du décalage temporel
    % L'indice du pic permet de déduire le décalage (delay) :
    % delay = indice du pic - longueur du préambule différentiel + 1
    delay = idx_max - length(dphase_ref) + 1;
end
