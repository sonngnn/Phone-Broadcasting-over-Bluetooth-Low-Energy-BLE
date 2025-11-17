function binVec = my_de2bi(n, numBits, order)
    if nargin < 2
        numBits = ceil(log2(n + 1));  % Nombre de bits minimal nécessaire
    end
    if nargin < 3
        order = 'right-msb';  % Par défaut, correspond au comportement de `de2bi`
    end
    
    binStr = dec2bin(n, numBits);  % Convertit en chaîne binaire
    binVec = double(binStr) - '0'; % Convertit la chaîne en tableau numérique

    % Gestion de l'ordre des bits
    if strcmpi(order, 'right-msb')
        binVec = fliplr(binVec);  % Right-MSB (par défaut)
    elseif ~strcmpi(order, 'left-msb')
        error("Option invalide. Utiliser 'right-msb' ou 'left-msb'.");
    end
end
