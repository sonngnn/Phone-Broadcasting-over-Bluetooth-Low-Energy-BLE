function hexVec = bitsToHex(bitVec)
    % Vérifie que l'entrée est bien un vecteur binaire
    if ~isvector(bitVec) || ~all(ismember(bitVec, [0, 1]))
        error('L''entrée doit être un vecteur contenant uniquement des 0 et 1.');
    end
    
    % Vérifie que la longueur du vecteur est un multiple de 4
    if mod(length(bitVec), 4) ~= 0
        error('La longueur du vecteur de bits doit être un multiple de 4.');
    end
    
    % Conversion des bits en groupes de 4 en hexadécimal
    hexVec = "";
    for i = 1:4:length(bitVec)
        % Extraction du groupe de 4 bits
        bitGroup = bitVec(i:i+3);
        % Conversion en nombre décimal
        decimalValue = bin2dec(num2str(bitGroup));
        % Conversion en caractère hexadécimal et concaténation
        hexVec = strcat(hexVec, dec2hex(decimalValue));
    end
end
