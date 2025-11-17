function codeword = add_crc(pdu, crc_init)
    % Ajoute un CRC à une trame PDU en utilisant le polynôme Bluetooth.
    %
    % Args:
    %   pdu      : Vecteur (row ou column) de bits (0 ou 1) représentant la PDU.
    %   crc_init : Valeur d'initialisation du CRC sous forme hexadécimale (ex: '555555').
    %
    % Returns:
    %   codeword : Vecteur de bits, correspondant à pdu concaténé avec les 24 bits du CRC.

    % Polynôme CRC Bluetooth : x^24 + x^10 + x^9 + x^6 + x^4 + x^3 + x + 1
    % Représenté en hexa par 0x100065B
    CRC_POLYNOMIAL = hex2dec('100065B');  % 0x100065B

    % Convertir la valeur d'initialisation CRC de l'hexadécimal vers un entier 24 bits
    crc_value = hex2dec(crc_init);  % Sur 24 bits max

    %Calcul du masque pour le bitand
    masque = hex2dec('FFFFFF');

    % --- Calcul du CRC sur la PDU ---
    % Pour chaque bit de pdu, on :
    %  1) Récupère le bit MSB actuel (bit 23) de crc_value
    %  2) Décale crc_value à gauche de 1 bit
    %  3) Si (bit XOR MSB) == 1, on XOR avec CRC_POLYNOMIAL

    nBits = length(pdu);
    for i = 1:nBits
        % Récupérer le bit de poids fort (MSB) de crc_value
        %msb = bitand(bitshift(crc_value, -23), 1);
        msb = mod(floor(crc_value/2^23),2);
    
        crc_saved(i) = crc_value;
        
        % Décalage à gauche de 1 bit, en conservant 24 bits (masque 0xFFFFFF)
        crc_value = bitand(bitshift(crc_value, 1), masque);

        crc_saved2(i) = crc_value;


        % Si bit ^ msb == 1, on XOR crc_value avec le polynôme
        if bitxor(pdu(i), msb)
            crc_value = bitxor(crc_value, CRC_POLYNOMIAL);
        end

        
    end

    % --- Extraction des 24 bits du CRC final ---
    % En Python : [(crc_value >> i) & 1 for i in range(23, -1, -1)]
    % On récupère d'abord le MSB (bit 23), puis jusqu'au LSB (bit 0).

    crc_bits = zeros(1, 24);  % Vecteur de 24 bits
    for i = 23:-1:0
        idx = 24 - i;  % Convertir l'index i (descendant) en index MATLAB ascendant
        crc_bits(idx) = bitand(bitshift(crc_value, -i), 1);
    end

    crc_bits = crc_bits.';

    % --- Concaténer la PDU et les bits du CRC ---
    codeword = [pdu(:);crc_bits(:)]; 
end
