function [delta_max, rho_max] = synchro_gmsk(received_signal, preamble_baseband)
    % Synchronisation temporelle GMSK
    % received_signal : signal reçu (complexe), sur fréquence porteuse
    % preamble_baseband : préambule en bande de base (complexe)

    % Calcul de la puissance du signal reçu
    rl = abs(received_signal).^2;

    Tp = length(preamble_baseband); % Longueur du préambule
    delta_max = 0;
    rho_max = 0;

    % Cross-corrélation normalisée
    for dt = 1:(length(rl) - Tp + 1)
        num = sum(rl(dt:(dt+Tp-1)) .* abs(preamble_baseband).^2);
        den = sqrt(sum(rl(dt:(dt+Tp-1)).^2) * sum(abs(preamble_baseband).^4));
        rho = abs(num / den);
        if rho > rho_max
            rho_max = rho;
            delta_max = dt;
        end
    end
end
