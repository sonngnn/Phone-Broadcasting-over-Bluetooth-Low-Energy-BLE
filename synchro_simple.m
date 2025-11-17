function [delay, corr_val] = synchro_simple(rx_signal, preamble)
    % synchro_simple: Synchronisation temporelle par corrélation simple
    %
    % Cette fonction réalise la synchronisation en corrélant le signal reçu avec
    % le préambule connu. Le pic de corrélation correspond à l'endroit où le
    % préambule est aligné avec le signal reçu, ce qui permet d'estimer le décalage.
    %
    % Inputs:
    %   - rx_signal : Signal reçu (vecteur, réel ou complexe)
    %   - preamble  : Séquence préambule connue (vecteur)
    %
    % Output:
    %   - delay     : Décalage temporel estimé (en nombre d'échantillons) indiquant
    %                 la position de début du préambule dans rx_signal
    %   - corr_val  : Vecteur contenant la corrélation (pour diagnostic ou visualisation)
    
    % Vérification des entrées
    if nargin < 2
        error('Usage: [delay, corr_val] = synchro_simple(rx_signal, preamble)');
    end

    % Calcul de la corrélation croisée :
    % Pour ce faire, on effectue la convolution du signal reçu avec la version
    % inversée (et conjuguée pour couvrir le cas complexe) du préambule.
    % Cette opération est équivalente à une corrélation.
    corr_val = conv(rx_signal, fliplr(conj(preamble)));
    
    % Recherche du pic de corrélation
    [~, idx_max] = max(abs(corr_val));
    
    % Calcul du décalage temporel :
    % La longueur du préambule doit être prise en compte pour ajuster l'indice.
    delay = idx_max - length(preamble) + 1;
end