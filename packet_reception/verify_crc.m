function [is_valid, data_without_crc] = verify_crc(codeword, crc_init)
    % Vérifie le CRC Bluetooth d'un codeword (PDU + CRC)
    %
    % Args:
    %   codeword     : Vecteur binaire contenant la PDU + CRC (taille >= 24 bits)
    %   crc_init     : Chaîne hexadécimale de l'init CRC (ex: '555555')
    %
    % Returns:
    %   is_valid         : Vrai si CRC correct
    %   data_without_crc : La PDU seule si CRC valide, sinon tableau vide

    CRC_POLYNOMIAL = hex2dec('100065B');  % x^24 + x^10 + x^9 + x^6 + x^4 + x^3 + x + 1
    crc_value = hex2dec(crc_init);        % Initialisation CRC (sur 24 bits)

    if length(codeword) < 24
        error('La trame est trop courte pour contenir un CRC.');
    end

    % Séparation PDU / CRC
    pdu = codeword(1:end-24);
    crc_received = codeword(end-23:end);

    % Recalcul du CRC à partir du PDU
    for i = 1:length(pdu)
        msb = bitand(bitshift(crc_value, -23), 1);  % Bit 23
        crc_value = bitand(bitshift(crc_value, 1), hex2dec('FFFFFF'));  % Déplacement gauche (24 bits)
        if bitxor(pdu(i), msb)
            crc_value = bitxor(crc_value, CRC_POLYNOMIAL);
        end
    end

    % Conversion crc_value en bits (MSB -> LSB)
    crc_computed = zeros(1, 24);
    for i = 23:-1:0
        idx = 24 - i;
        crc_computed(idx) = bitand(bitshift(crc_value, -i), 1);
    end

    % Comparaison avec le CRC reçu
    is_valid = isequal(crc_computed, crc_received);

    if is_valid
        data_without_crc = pdu;
    else
        data_without_crc = [];
    end
end
