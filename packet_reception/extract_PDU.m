function pdu_info = extract_PDU(pdu_bits)
    % Extrait les champs d’un PDU BLE sans conversion décimale
    %
    % Args:
    %   pdu_bits : Vecteur binaire (0/1), sans CRC (min 16 bits)
    %
    % Returns:
    %   pdu_info : Structure contenant :
    %              - header_bits (1x8)
    %              - length_bits (1x8)
    %              - payload_bits (1xN, N multiple de 8)

    if length(pdu_bits) < 16
        error('Le PDU est trop court pour contenir Header + Length.');
    end

    % Séparation des champs
    header_bits = pdu_bits(1:8);
    length_bits = pdu_bits(9:16);

    % Extraire la longueur en binaire (juste pour découper)
    payload_len = bin2dec(regexprep(num2str(length_bits), '\s+', ''));  % utilisé uniquement pour couper
    total_len = 16 + payload_len * 8;

    if length(pdu_bits) < total_len
        warning('Le PDU est plus court que ce que le champ Length indique.');
        payload_bits = pdu_bits(17:end);
    else
        payload_bits = pdu_bits(17:16 + payload_len * 8);
    end

    % Remplir la structure de sortie
    pdu_info.header_bits = header_bits;
    pdu_info.length_bits = length_bits;
    pdu_info.payload_bits = payload_bits;

    adva = payload_bits(1:48);
    pdu_info.advA = adva;

    % length_adstruct = payload_bits(49:56);
    % pdu_info.length_adstruct = length_adstruct;

    ad_structure = payload_bits(49:end);
    pdu_info.ad_structure = ad_structure;

    length_ads = ad_structure(1:8);
    pdu_info.length_ads = length_ads;
    pdu_info.length_ads_dec = bin2dec(regexprep(num2str(length_ads), '\s+', ''));

    ad_type = ad_structure(9:16);
    pdu_info.ad_type = ad_type;

    sigle = ad_structure(17:32);
    pdu_info.sigle = sigle;

    data = ad_structure(33:pdu_info.length_ads_dec);
    pdu_info.data = data;
end
