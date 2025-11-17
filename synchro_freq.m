function out = synchro_freq(rx)
% SYNCHRO_FREQ  PLL ordre 2 (PI) pour corriger dérive freq./phase
%   rx  : signal aligné temporellement (vecteur complexe)
%   out : même taille, phase corrigée

    M  = 2;      % binaire GMSK
    Kp = 0.1;    % gain P
    Ki = 0.01;   % gain I

    Nsig  = length(rx);
    theta = zeros(Nsig,1);
    fi    = zeros(Nsig,1);
    out   = zeros(size(rx));

    out(1) = rx(1);
    for k = 2:Nsig
        % correction d’entrée
        out(k) = rx(k) * exp(-1i*theta(k-1));
        % erreur de phase
        z   = out(k).^M;      z = z./abs(z);
        err = imag(z * conj(out(k).^M));
        % PI
        fi(k)    = fi(k-1) + Ki*err;
        theta(k) = theta(k-1) + Kp*err + fi(k);
    end
end
