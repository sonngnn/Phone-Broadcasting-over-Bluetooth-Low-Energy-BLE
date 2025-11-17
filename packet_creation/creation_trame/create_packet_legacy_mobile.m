function full_packets = create_packet_legacy_mobile(fragments, primary_channel_index, advA_bi, multiple_send, data_type, name_flag, name, discoverable_flag, SIG, notif)
    % Parameters for extended
    preamble = [0 1 0 1 0 1 0 1];  
    access_address_hex = {'8', 'E', '8', '9', 'B', 'E', 'D', '6'}; % Same defined for all Bluetooth packets 
    access_address_bi = hexCellToBinary(access_address_hex);
    default_CRC_init = '555555';
    nb_different_packet = length(fragments);

    if strcmp(name_flag, "Y") == 1
        local_name_bi = hexToBinaryLSB(name);
        local_name_length = length(local_name_bi) / 8; % Taille du nom en octets
    end
    

    % Create headers
    header_legacy = [0 0 0 0 ... % PDU TYPE for ADV_EXT_IND
                                 0 ...   % RFU = Bit unused
                                 1 ...   % Chsel = Simple algorithm of Frequency Hopping
                                 1 ...   % TxAdd = Public address of transmitter
                                 0];     % RxAdd = Public address of receiver


    % Pre-allocating
    
    %advData = preallocating_cell(nb_different_packet, multiple_send, max_length_advData, last_length_advData);
    %payload = preallocating_cell(nb_different_packet, multiple_send, max_length_payload, last_length_payload);
    %pdu = preallocating_cell(nb_different_packet, multiple_send, max_length_pdu, last_length_pdu);

    % data_type sur 1 octet pour réception sur mobile
    data_type_mobile = repmat(data_type(1),1,4);
    data_type_mobile = [data_type_mobile repmat(data_type(2),1,4)];

    if strcmp(notif, "Y") == 1
        data_type_mobile = ones(1,8);
    end
    
    SIG_bi = my_de2bi(SIG, 16, "right-msb"); 
    %SIG_bi = [SIG_bi(9:16) SIG_bi(1:8)]; % Inversion pour réception

    % Pour notif
    notif_length = my_de2bi(3, 8, "right-msb"); % A changer si on enlève l'octet ici
    notif_type = my_de2bi(0x03,8,"right-msb");
    notif_UUID = my_de2bi(0x180D,16,"right-msb");
    %notif_dedans = [1 0 1 0 1 0 1 0];

    % For each packet, add the header to the fragment, mutiple_send times
    for fragment_number=1:nb_different_packet % Total number of cells (different packets)
        fragment_number_bi = my_de2bi(fragment_number,16,"right-msb"); % fragment n°
        fragment_number_max_bi = my_de2bi(nb_different_packet,16,"right-msb");



        % If coded with 2 bytes
        fragment_number_bi = [fragment_number_bi(9:16) fragment_number_bi(1:8)];
        fragment_number_max_bi = [fragment_number_max_bi(9:16) fragment_number_max_bi(1:8)];
        
            % We fill in advData with information on the current package
            adData{fragment_number}= [data_type_mobile ... % Type of file sent
                                              fragment_number_bi ... % packet n°
                                              fragment_number_max_bi ... % number max packet
                                              fragments{fragment_number}];  

            user_data_length = length(adData{fragment_number})/8 + 3;

            advData{fragment_number} = [my_de2bi(user_data_length, 8, "right-msb") my_de2bi(0xFF, 8, "right-msb") SIG_bi adData{fragment_number}]; %ad structure de base en manufacturer data

            if strcmp(discoverable_flag, "Y") == 1
                advData_disc{fragment_number} = [my_de2bi(0x02, 8, "right-msb") my_de2bi(0x01, 8, "right-msb") my_de2bi(0x06, 8, "right-msb") advData{fragment_number}];
            else
                advData_disc{fragment_number} = advData{fragment_number};
            end

            if strcmp(name_flag, "Y") == 1
                advData_name{fragment_number} = [my_de2bi(local_name_length + 1, 8, "right-msb") ... % Longueur totale
                    my_de2bi(0x09, 8, "right-msb") ... % Type: Complete Local Name
                    local_name_bi ...
                    advData_disc{fragment_number}]; % Nom en binaire
            else
                advData_name{fragment_number} = advData_disc{fragment_number};
            end

            if strcmp(notif, "Y") == 1
                advData_notif{fragment_number} = [notif_length notif_type notif_UUID advData_name{fragment_number}];
            else
                advData_notif{fragment_number} = advData_name{fragment_number};
            end

            payload{fragment_number} = [advA_bi advData_notif{fragment_number}]; 

            % Compute payload length for header
            length_payload = my_de2bi(length(payload{fragment_number})/8,8,"right-msb");

            pdu{fragment_number} = [header_legacy length_payload payload{fragment_number}]; % PDU with header  

            pdu_crc{fragment_number} = add_crc(pdu{fragment_number}.',default_CRC_init).';

            pdu_whitened{fragment_number} = whitening_ble(pdu_crc{fragment_number}.',primary_channel_index).'; % CRC and Whitening on PDU
            
            full_packets{fragment_number} = [preamble access_address_bi pdu_whitened{fragment_number}];
               
    end 
    

    

end

