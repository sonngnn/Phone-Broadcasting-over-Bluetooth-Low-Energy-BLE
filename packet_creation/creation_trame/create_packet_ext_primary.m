function full_packets = create_packet_ext_primary(fragments, primary_channel_index, advA_bi, multiple_send, data_type, ble_mode, length_ext_frag_max, discoverable_flag, name_flag, name)
    % Parameters for extended
    preamble_ext_125k = [0 0 1 1 1 1 0 0]; % Preamble for extended Coded
    preamble_ext_1M = [0 1 0 1 0 1 0 1]; % Preamble for extended Uncoded
    
    access_address_hex = {'8', 'E', '8', '9', 'B', 'E', 'D', '6'}; % Same defined for all Bluetooth packets 
    access_address_bi = hexCellToBinary(access_address_hex);
    default_CRC_init = '555555';
    
    nb_different_packet = length(fragments);
    
    ad_type_bi = my_de2bi(0xFF,8,"right-msb");
    ad_sig_bi = my_de2bi(0x0000,16,"right-msb");

    % Create headers
    header_without_length = [1 1 1 0 ... % PDU TYPE for ADV_EXT_IND
                                 0 ...   % RFU = Bit unused
                                 0 ...   % Chsel = Simple algorithm of Frequency Hopping
                                 1 ...   % TxAdd = Public address of transmitter
                                 0];     % RxAdd = Public address of receiver

    ext_header_advA = [1 1 1 0 0 0 ...     % Length of extended header : 7 bytes
                       0 0 ...             % advMode : non-connectable & non-scannable
                       1 0 0 0 0 0 0 0 ... % Extended Header Flags only for AdvA
                       advA_bi];           % AdvA 

    % For each packet, add the header to the fragment, mutiple_send times
    for fragment_number=1:nb_different_packet % Total number of cells (different packets)
            fragment_number_bi = my_de2bi(fragment_number,9,"right-msb"); % fragment n°
               
            for nb_sent=1:multiple_send
                % We fill in advData with information on the current package
                nb_sent_bi = my_de2bi(nb_sent,4,"right-msb");
                if nb_sent==multiple_send
                    advData{fragment_number}(nb_sent,:) = [fragment_number_bi ... % packet n°
                                                  nb_sent_bi ... % same packet sent nb_sent times
                                                  1 ... % last time this packet is sent
                                                  data_type ... % video/audio/text/image
                                                  fragments{fragment_number}];  
                else
                    advData{fragment_number}(nb_sent,:) = [fragment_number_bi nb_sent_bi 0 data_type fragments{fragment_number}];
                end

                % Order the data in an ADStructure
                length_advdata = length(advData{fragment_number}(nb_sent,:))/8;
                length_ad_structure_bi = my_de2bi(length_advdata+3,8,"right-msb"); % Add the length of ADStructure
                if strcmp(discoverable_flag, 'Y') == 1  
                    discoverable_length = my_de2bi(0x02,8,"right-msb");
                    discoverable_type = my_de2bi(0x01,8,"right-msb");
                    discoverable_flag_idx = my_de2bi(0x06,8,"right-msb"); 
                    advData_ad_structure{fragment_number}(nb_sent, :) = [discoverable_length, discoverable_type, discoverable_flag_idx, length_ad_structure_bi, ad_type_bi, ad_sig_bi, advData{fragment_number}(nb_sent,:)];
                else
                    advData_ad_structure{fragment_number}(nb_sent,:) = [length_ad_structure_bi, ad_type_bi, ad_sig_bi, advData{fragment_number}(nb_sent,:)];
                end
    
                payload{fragment_number}(nb_sent,:) = [ext_header_advA advData_ad_structure{fragment_number}(nb_sent,:)]; % Add the extended header with only advA filled in 
                
                % Compute payload length for header

                length_payload = my_de2bi(length(payload{fragment_number}(nb_sent,:))/8,8,"right-msb");

                pdu{fragment_number}(nb_sent,:) = [header_without_length length_payload payload{fragment_number}(nb_sent,:)]; % PDU with header  

                pdu_crc{fragment_number}(nb_sent,:) = add_crc(pdu{fragment_number}(nb_sent,:).',default_CRC_init).';

                pdu_whitened{fragment_number}(nb_sent,:) = whitening_ble(pdu_crc{fragment_number}(nb_sent,:).',primary_channel_index).'; % CRC and Whitening on PDU
                
                if ble_mode == "1M"
                    full_packets{fragment_number}(nb_sent,:) = [preamble_ext_1M access_address_bi pdu_whitened{fragment_number}(nb_sent,:)];
                else % ble_mode == 125k
                    full_packet_nfec{fragment_number}(nb_sent,:) = [preamble_ext_125k ... 
                                          access_address_bi ...
                                          00 ... % CI for S =8
                                          000 ... % TERM1
                                          pdu_corr{fragment_number}(nb_sent,:) ...
                                          000]; % TERM2
                    full_packets{fragment_number}(nb_sent,:) = fec(full_packet_nfec{fragment_number}(nb_sent,:), ble_mode); % FEC of the packet (/!\ preamble not encoded by FEC)
                end
           end
               
    end      
    

end
