function full_packets = create_packet_legacy(fragments, primary_channel_index, advA_bi, multiple_send, data_type,name_flag, name, discoverable_flag, SIG)
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


    % For each packet, add the header to the fragment, mutiple_send times
    
    for fragment_number=1:nb_different_packet % Total number of cells (different packets)
            fragment_number_bi = my_de2bi(fragment_number,9,"right-msb"); % fragment n°
               
            for nb_sent=1:multiple_send
                % We fill in advData with information on the current package
                nb_sent_bi = my_de2bi(nb_sent,4,"right-msb");
                if nb_sent==multiple_send
                    adData{fragment_number}(nb_sent,:) = [fragment_number_bi ... % packet n°
                                                  nb_sent_bi ... % same packet sent nb_sent times
                                                  1 ... % last time this packet is sent
                                                  data_type ... % video/audio/text/image
                                                  fragments{fragment_number}];  
                else
                    adData{fragment_number}(nb_sent,:) = [fragment_number_bi nb_sent_bi 0 data_type fragments{fragment_number}];
                end

                user_data_length = length(adData{fragment_number}(nb_sent,:))/8 + 3;
    
                advData{fragment_number}(nb_sent,:) = [my_de2bi(user_data_length, 8, "right-msb") my_de2bi(0xFF, 8, "right-msb") my_de2bi(SIG, 16, "right-msb") adData{fragment_number}(nb_sent,:)]; %ad structure de base en manufacturer data

                if strcmp(discoverable_flag, "Y") == 1
                    advData_disc{fragment_number}(nb_sent,:) = [my_de2bi(0x02, 8, "right-msb") my_de2bi(0x01, 8, "right-msb") my_de2bi(0x06, 8, "right-msb") advData{fragment_number}(nb_sent,:)];
                else
                    advData_disc{fragment_number}(nb_sent,:) = advData{fragment_number}(nb_sent,:);
                end

                if strcmp(name_flag, "Y") == 1
                    advData_name{fragment_number}(nb_sent,:) = [my_de2bi(local_name_length + 1, 8, "right-msb") ... % Longueur totale
                        my_de2bi(0x09, 8, "right-msb") ... % Type: Complete Local Name
                        local_name_bi ...
                        advData_disc{fragment_number}(nb_sent,:)]; % Nom en binaire
                else
                    advData_name{fragment_number}(nb_sent,:) = advData_disc{fragment_number}(nb_sent,:);
                end

                payload{fragment_number}(nb_sent,:) = [advA_bi advData_name{fragment_number}(nb_sent,:)]; 

                % Compute payload length for header
                length_payload = my_de2bi(length(payload{fragment_number}(nb_sent,:))/8,8,"right-msb");

                pdu{fragment_number}(nb_sent,:) = [header_legacy length_payload payload{fragment_number}(nb_sent,:)]; % PDU with header  

                pdu_crc{fragment_number}(nb_sent,:) = add_crc(pdu{fragment_number}(nb_sent,:).',default_CRC_init).';

                pdu_whitened{fragment_number}(nb_sent,:) = whitening_ble(pdu_crc{fragment_number}(nb_sent,:).',primary_channel_index).'; % CRC and Whitening on PDU
                
                full_packets{fragment_number}(nb_sent,:) = [preamble access_address_bi pdu_whitened{fragment_number}(nb_sent,:)];
           end
               
    end      
    

end

