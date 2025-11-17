function [f, Man_pxx_dBmParHz] = myPSD(signal, N, fs)
    f = -fs/2:fs/N:fs/2-fs/N;
    Nb_PSD = floor(length(signal)/N);       % On calcule le nombre de FFT que l'on peut moyenner sans chevauchement
    Man_pxx_dBmParHz = 1/N*fftshift(mean(abs(fft(reshape(signal(1:Nb_PSD*N),N,Nb_PSD),N)).^2,2))*1000; % *1000 pour passer en mW, PSD unité mWatt/Hz
    
end
