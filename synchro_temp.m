function idx = synchro_temp(rx, template, sps)
% SYNCHRO_TEMP  repère le début du préambule aligné sur symbole
%   rx       : signal reçu (vecteur complexe)
%   template : préambule oversamplé (vecteur complexe)
%   sps      : échantillons par symbole
%   idx      : 1re position (multiple de sps) où commence la trame

    % 1) corrélation croisée (module)
    c = abs(conv(rx, flipud(conj(template)), 'same'));

    % 2) on ne cherche que dans les premiers samples :
    searchLen = min(length(c), length(template)*10);
    [~, peak] = max(c(1:searchLen));

    % 3) recentrage au centre du template
    idx = peak - floor(length(template)/2) + 1;
    idx = max(idx,1);

    % 4) recaler sur frontière symbole
    rem = mod(idx-1, sps);
    if rem ~= 0
        idx = idx + (sps - rem);
    end

    % 5) borne
    if idx > length(rx)
        error('synchro_temp: index hors bornes (%d > %d)', idx, length(rx));
    end
end
