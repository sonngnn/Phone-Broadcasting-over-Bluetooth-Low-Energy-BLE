function [full_packets_primary, full_packets_secondary] = create_packet_ext_primary_secondary(fragments, primary_channel_index, secondary_channel_index, advA_bi, multiple_send, data_type, ble_mode, time_between_primary_and_secondary, time_between_ext_primaries,data_rate)
    % Parameters for extended
    preamble_ext = [0 0 1 1 1 1 0 0]; % Preamble for extended repeated 10 times
    access_address_hex = {'8', 'E', '8', '9', 'B', 'E', 'D', '6'}; % Same defined for all Bluetooth packets 
    access_address_bi = hexCellToBinary(access_address_hex);
    default_CRC_init = '555555';
    nb_different_packet = length(fragments);


    % Create headers
    header_without_length = [0 1 1 1 ... % PDU TYPE for ADV_EXT_IND
                             0 ...       % RFU = Bit unused
                             0 ...       % Chsel = Simple algorithm of Frequency Hopping
                             0 ...       % TxAdd = Public address of transmitter
                             0];         % RxAdd = Public address of receiver

    ext_header_primary = [0 1 0 1 0 0 ...     % 13 bytes
                          0 0 ...
                          1 0 0 1 1 0 0 0 ... % Extended Header Flags for AdvA, ADI & AuxPtr 
                          advA_bi];

    ext_header_secondary = [0 0 1 0 0 0 ...   % Length of extended header : 4 bytes
                            0 0 ...           % advMode for non-connectable & non-scannable
                            0 0 0 1 0 0 0 0]; % Extended Header Flags for ADI (identification of a packet)
    % ADI's field will be filled in as the payload will be built

    % Defining time to wait for the field AuxPtr
    nb_bytes_ext_primary_packet = 1 + 4 + 2 + 1 + 1 + 6 + 3 + 3; % Preamble + AA + header + Extended header length+advMode + ExtFlags + AdvA + AuxPtr + CRC 
    duration_ext_primary_packet = nb_bytes_ext_primary_packet / data_rate;
    total_time_interval = (duration_ext_primary_packet+time_between_ext_primaries)*multiple_send + time_between_primary_and_secondary;
    total_time_interval_updated = total_time_interval; 


    % For each packet, add the header to the fragment, mutiple_send times

    for fragment_number=1:nb_different_packet % Total number of cells (different packets)
        fragment_number_bi = my_de2bi(fragment_number,9,"right-msb"); % fragment n°
        
        for nb_sent=1:multiple_send
            % We fill in advData with information on the current package
            nb_sent_bi = my_de2bi(nb_sent,4,"right-msb");
            if nb_sent==multiple_send
                % No data in advData_primary, only the field AuxPtr is
                % useful
                advData_primary{fragment_number}(nb_sent,:) = [fragment_number_bi ... % packet n°
                                              nb_sent_bi ...                  % same packet sent nb_sent times
                                              1 ...                           % last time this packet is sent
                                              data_type];                     % video/audio/text/image
                
                advData_secondary{fragment_number}(nb_sent,:) = [fragment_number_bi ... % packet n°
                                              nb_sent_bi ...                  % same packet sent nb_sent times
                                              1 ...                           % last time this packet is sent
                                              data_type ...                   % video/audio/text/image
                                              fragments{fragment_number}];  
            else
                advData_secondary{fragment_number}(nb_sent,:) = [fragment_number_bi nb_sent_bi 0 data_type fragments{fragment_number}];
                advData_primary{fragment_number}(nb_sent,:) = [fragment_number_bi nb_sent_bi 0 data_type];
            end


            % Calculating the fields to fill for AuxPtr (updating the time to wait)
            
            % Offset Units
            auxptr_offset_units = 0; % 30us if 0 and 300us if 1
            if auxptr_offset_units == 0
                auxptr_offset_units_us = 30;
            else
                auxptr_offset_units_us = 300;
            end

            % AUX offset
            AUX_offset = floor(total_time_interval_updated/auxptr_offset_units_us) -1 ;
            auxptr_AUX_offset = de2bi(AUX_offset,13,"right-msb");
            
            % AUX Phy
            if ble_mode == "1M"
                auxptr_phy = fliplr([0 0 0]); % [0 0 0] for 1M, [0 0 1] for 2M and [0 1 0] for CODED
            else
                auxptr_phy = fliplr([0 1 0]);
            end         
            
            % ADI
            DID = fragment_number_bi; % Identifier for each different packet
            SID = [0 0 0 0]; % Always the same of type of data

            ext_header_primary_filled = [ext_header_primary DID SID secondary_channel_index 1 auxptr_offset_units auxptr_AUX_offset auxptr_phy];
            ext_header_secondary_filled = [ext_header_secondary DID SID];

            payload_primary{fragment_number}(nb_sent,:) = [ext_header_primary_filled advData_primary{fragment_number}(nb_sent,:)]; % Add the extended header with advA, ADI & AuxPtr filled in 
            payload_secondary{fragment_number}(nb_sent,:) = [ext_header_secondary_filled advData_secondary{fragment_number}(nb_sent,:)]; % Add the extended header with only ADI filled in 


            % Compute payload length for header
            length_payload_primary = my_de2bi(length(payload_primary{fragment_number}(nb_sent,:))/8,8,"right-msb");
            length_payload_secondary = my_de2bi(length(payload_secondary{fragment_number}(nb_sent,:))/8,8,"right-msb");

            pdu_primary{fragment_number}(nb_sent,:) = [header_without_length length_payload_primary payload_primary{fragment_number}(nb_sent,:)]; % PDU with header  
            pdu_secondary{fragment_number}(nb_sent,:) = [header_without_length length_payload_secondary payload_secondary{fragment_number}(nb_sent,:)]; % PDU with header 

            pdu_corr_primary{fragment_number}(nb_sent,:) = whitening_ble(add_crc(pdu_primary{fragment_number}(nb_sent,:),default_CRC_init),primary_channel_index); % CRC and Whitening on PDU
            pdu_corr_secondary{fragment_number}(nb_sent,:) = whitening_ble(add_crc(pdu_secondary{fragment_number}(nb_sent,:),default_CRC_init),secondary_channel_index); % CRC and Whitening on PDU


            if ble_mode == "1M"
                full_packets_primary{fragment_number}(nb_sent,:) = [preamble_ext access_address_bi pdu_corr_primary{fragment_number}(nb_sent,:)];
                full_packets_secondary{fragment_number}(nb_sent,:) = [preamble_ext access_address_bi pdu_corr_secondary{fragment_number}(nb_sent,:)];
            else % ble_mode == 125k
                full_packet_nfec_primary{fragment_number}(nb_sent,:) = [preamble_ext ... 
                                      access_address_bi ...
                                      00 ... % CI for S =8
                                      000 ... % TERM1
                                      pdu_corr_primary{fragment_number}(nb_sent,:) ...
                                      000]; % TERM2
                
                full_packet_nfec_secondary{fragment_number}(nb_sent,:) = [preamble_ext ... 
                                      access_address_bi ...
                                      00 ... % CI for S =8
                                      000 ... % TERM1
                                      pdu_corr_secondary{fragment_number}(nb_sent,:) ...
                                      000]; % TERM2

                full_packets_primary{fragment_number}(nb_sent,:) = fec(full_packet_nfec_primary{fragment_number}(nb_sent,:),ble_mode); % FEC the packet (/!\ preamble not encoded by FEC)
                full_packets_secondary{fragment_number}(nb_sent,:) = fec(full_packet_nfec_secondary{fragment_number}(nb_sent,:),ble_mode); % 

                % Update time to wait before next packet
                total_time_interval_updated = total_time_interval - (time_between_ext_primaries + duration_ext_primary_packet);
            end
            % Resetting the time to wait between 1st primary packet and 1st secondary packet
            total_time_interval_updated = total_time_interval;
        end

    end
end