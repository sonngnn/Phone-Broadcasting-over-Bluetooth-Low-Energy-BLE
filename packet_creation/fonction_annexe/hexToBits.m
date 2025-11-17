function bitVec = hexToBits(hexVec)
    % Vérifie que l'entrée est bien un vecteur de char
    if ~ischar(hexVec) && ~isstring(hexVec)
        error('L''entrée doit être une chaîne de caractères.');
    end
    
    % Initialisation du vecteur de bits
    bitVec = [];
    
    for i = 1:length(hexVec)
        % Convertit le caractère hexadécimal en nombre décimal
        decimalValue = hex2dec(hexVec(i));
        % Convertit le nombre décimal en binaire sur 4 bits et stocke sous forme de vecteur de double
        bitVec = [bitVec, double(dec2bin(decimalValue, 4) - '0')];
    end
end
