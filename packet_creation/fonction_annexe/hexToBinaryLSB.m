function binaryVector = hexToBinaryLSB(hexArray)
    % hexToBinaryLSB Convertit un tableau de valeurs hexadécimales en un vecteur binaire
    % avec inversion des bits (LSB à gauche).
    %
    % Entrée :
    %   hexArray - Cell array de chaînes hexadécimales (ex: {'32', 'A6', 'F6', ...})
    %
    % Sortie :
    %   binaryVector - Vecteur binaire résultant avec inversion des bits

    binaryVector = []; % Initialisation du vecteur binaire

    for i = 1:length(hexArray)
        % Convertir l'hexadécimal en entier
        decimalValue = hex2dec(hexArray{i});
        
        % Convertir en binaire 8 bits
        binValue = dec2bin(decimalValue, 8);
        
        % Inverser les bits (LSB à gauche)
        reversedBin = flip(binValue);
        
        % Ajouter au vecteur final
        binaryVector = [binaryVector, reversedBin - '0']; % Convertir char en nombre
    end
end
