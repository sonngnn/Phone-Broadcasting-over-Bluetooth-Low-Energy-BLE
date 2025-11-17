function signal_bruite=add_complex_noise(signal,RSB) % Fonction à revoir, pas testée
h = signal(:);
L = length(h); % Length of the signal
RSB_lin=10^(RSB/10);
% Calculate power values
Ps = sum(abs(h.^2))/L; % Power of the original signal
b =  randn(L, 1)+1i*randn(L, 1); % BBGC de sigma =1
Pb = sum(abs(b.^2))/L; % Power of the noise (BBGC de sigma =1)
sigma = sqrt(Ps/(Pb*RSB_lin));
signal_bruite = sigma*b + h;