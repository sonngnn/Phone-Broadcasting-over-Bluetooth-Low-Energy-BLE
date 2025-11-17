function [full_packets_primary, full_packets_secondary] = create_packet_ext_chained(fragments, primary_channel_index, secondary_channel_index, advA_bi, multiple_send, data_type, ble_mode, time_between_primary_and_secondary, time_between_ext_primaries, time_between_ext_secondaries, data_rate)
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


    ext_header_secondary = [0 1 1 0 0 0 ... % Length of extended header : 6 bytes
                            0 0 ... % advMode for non-connectable & non-scannable
                            0 0 0 1 1 0 0 0]; 

    ext_header_secondary_last_chain = [0 0 1 0 0 0 ...   % Length of extended header : 4 bytes
                            0 0 ...           % advMode for non-connectable & non-scannable
                            0 0 0 1 0 0 0 0]; % Extended Header Flags for ADI (identification of a packet)
    % ADI's field will be filled in as the payload will be built


    % Defining time to wait for the field AuxPtr 
    % For the extended header in the primary channel :
    nb_bytes_ext_primary_packet = 1 + 4 + 2 + 1 + 1 + 6 + 3 + 3; % Preamble + AA + header + Extended header length+advMode + ExtFlags + AdvA + AuxPtr + CRC 
    duration_ext_primary_packet = nb_bytes_ext_primary_packet / data_rate;
    total_time_interval = (duration_ext_primary_packet+time_between_ext_primaries)*multiple_send + time_between_primary_and_secondary;
    total_time_interval_updated = total_time_interval; 

    % For the extended header in the secondary channel :

    if ble_mode == "1M"
        nb_bytes_max_ext_secondary_packet = 1+4+2+1+255+3; %Preamble + AA + header + ext_header(flags+advmode) + full AdvData + CRC (fields of ext_header fullfilled but it doesn't change the number of total bytes because it removes bytes of AdvData)
    else
        nb_bytes_max_ext_secondary_packet = 10 + (4 + 1 + 2 + 1 + 254 + 3)*8; % Same as before but with : CI+Term1+Term2 (1 byte), preamble longer & coding with S=8 so *8 for each byte
    end
 
    duration_max_ext_secondary_packet = nb_bytes_max_ext_secondary_packet / data_rate;
    total_time_interval_chaining = (duration_max_ext_secondary_packet+time_between_ext_secondaries)*multiple_send + time_between_ext_secondaries; % Time for all secondaries to be sent + duration between 2 secondary packets for chaining
    total_time_interval_chaining_updated = total_time_interval_chaining;

    % For each packet, add the header to the fragment, mutiple_send times

    for fragment_number=1:nb_different_packet % Total number of cells (different packets)
        fragment_number_bi = my_de2bi(fragment_number,9,"right-msb"); % fragment n°
        
        for nb_sent=1:multiple_send
            % We fill in advData with information on the current package
            nb_sent_bi = my_de2bi(nb_sent,4,"right-msb");
                if mod(fragment_number,6) == 1 % Chained packet only needs a primary header in every 6 packets
                    if nb_sent==multiple_send
                        advData_primary{ceil(fragment_number/6)}(nb_sent,:) = [fragment_number_bi ... % packet n°
                                      nb_sent_bi ...                                                  % same packet sent nb_sent times
                                      1 ...                                                           % last time this packet is sent
                                      data_type];                                                     % video/audio/text/image
                    else
                        advData_primary{ceil(fragment_number/6)}(nb_sent,:) = [fragment_number_bi nb_sent_bi 0 data_type];
                    end
                end
                if nb_sent == multiple_send
                    advData_secondary{fragment_number}(nb_sent,:) = [fragment_number_bi ... 
                                      nb_sent_bi ... 
                                      1 ... 
                                      data_type ... 
                                      fragments{fragment_number}];
                else
                    advData_secondary{fragment_number}(nb_sent,:) = [fragment_number_bi nb_sent_bi 0 data_type fragments{fragment_number}];
                end

            % Calculating the fields to fill for AuxPtr (updating the time to wait)
            
            if mod(fragment_number,6) == 1
                auxptr_offset_units_primary = 0; % 30us if 0 and 300us if 1
                    if auxptr_offset_units_primary == 0
                        auxptr_offset_units_us_primary = 30;
                    else
                        auxptr_offset_units_us_primary = 300;
                    end
                
                    % AUX offset
                    AUX_offset_primary = floor(total_time_interval_updated/auxptr_offset_units_us_primary) -1 ;
                    auxptr_AUX_offset_primary = de2bi(AUX_offset_primary,13,"right-msb");
                
                    % AUX Phy
                    if ble_mode == "1M"
                        auxptr_phy_primary = fliplr([0 0 0]); % [0 0 0] for 1M, [0 0 1] for 2M and [0 1 0] for CODED
                    else
                        auxptr_phy_primary = fliplr([0 1 0]);
                    end
                    
                    DID = fragment_number_bi; % % Identifier for each different packet
                    SID = [0 0 0 0];% Always the same of type of data

                    ext_header_primary_filled = [ext_header_primary DID SID secondary_channel_index 1 auxptr_AUX_offset_primary AUX_offset_primary auxptr_phy_primary];
                    payload_primary{ceil(fragment_number/6)}(nb_sent,:) = [ext_header_primary_filled advData_primary{ceil(fragment_number/6)}(nb_sent,:)];

                    length_payload_primary = my_de2bi(length(payload_primary{ceil(fragment_number/6)}(nb_sent,:))/8,8,"right-msb");
                    
                    pdu_primary{ceil(fragment_number/6)}(nb_sent,:) = [header_without_length length_payload_primary payload_primary{ceil(fragment_number/6)}(nb_sent,:)]; 
                    
                    pdu_corr_primary{ceil(fragment_number/6)}(nb_sent,:) = whitening_ble(add_crc(pdu_primary{ceil(fragment_number/6)}(nb_sent,:),default_CRC_init),primary_channel_index); % CRC and Whitening on PDU
                    if ble_mode == "1M"
                        full_packets_primary{ceil(fragment_number/6)}(nb_sent,:) = [preamble_ext access_address_bi pdu_corr_primary{ceil(fragment_number/6)}(nb_sent,:)];
                    else % ble_mode == 125k
                        full_packet_nfec_primary{ceil(fragment_number/6)}(nb_sent,:) = [preamble_ext ... 
                                                      access_address_bi ...
                                                      00 ... % CI pour S =8
                                                      000 ... % TERM1
                                                      pdu_corr_primary{ceil(fragment_number/6)}(nb_sent,:) ...
                                                      000]; % TERM2
                        full_packets_primary{ceil(fragment_number/6)}(nb_sent,:) = fec(full_packet_nfec_primary{ceil(fragment_number/6)}(nb_sent,:),ble_mode); 

                    end
            end
            
            if fragment_number == length(fragments) || mod(fragment_number,6) == 0
                    % In this case, no AuxPtr field because end of chain
                    DID = fragment_number_bi; 
                    SID = [0 0 0 0]; 

                    ext_header_ADI_filled = [ext_header_secondary_last_chain DID SID];
    
                    payload_secondary{fragment_number}(nb_sent,:) = [ext_header_ADI_filled advData_secondary{fragment_number}(nb_sent,:)];

            else

                auxptr_offset_units_secondary = 0; % 30us if 0 and 300us if 1
                if auxptr_offset_units_secondary == 0
                    auxptr_offset_units_us_secondary = 30;
                else
                    auxptr_offset_units_us_secondary = 300;
                end

                % AUX offset
                AUX_offset_secondary = floor(total_time_interval_chaining_updated/auxptr_offset_units_us_secondary) -1 ;
                auxptr_AUX_offset_secondary = de2bi(AUX_offset_secondary,13,"right-msb");
                
                % AUX Phy
                if ble_mode == "1M"
                    auxptr_phy_secondary = fliplr([0 0 0]); % [0 0 0] for 1M, [0 0 1] for 2M and [0 1 0] for CODED
                else
                    auxptr_phy_secondary = fliplr([0 1 0]);
                end
                
                DID = fragment_number_bi; 
                SID = [0 0 0 0]; 

                ext_header_secondary_filled = [ext_header_secondary DID SID secondary_channel_index 1 auxptr_offset_units_secondary auxptr_AUX_offset_secondary auxptr_phy_secondary];

                payload_secondary{fragment_number}(nb_sent,:) = [ext_header_secondary_filled advData_secondary{fragment_number}(nb_sent,:)]; 

            end

            % Compute payload length for header
            length_payload_secondary = my_de2bi(length(payload_secondary{fragment_number}(nb_sent,:))/8,8,"right-msb");

            pdu_secondary{fragment_number}(nb_sent,:) = [header_without_length length_payload_secondary payload_secondary{fragment_number}(nb_sent,:)]; % PDU with header 

            pdu_corr_secondary{fragment_number}(nb_sent,:) = whitening_ble(add_crc(pdu_secondary{fragment_number}(nb_sent,:),default_CRC_init),secondary_channel_index); % CRC and Whitening on PDU


            if ble_mode == "1M"
                full_packets_secondary{fragment_number}(nb_sent,:) = [preamble_ext access_address_bi pdu_corr_secondary{fragment_number}(nb_sent,:)];
            else % ble_mode == 125k                
                full_packet_nfec_secondary{fragment_number}(nb_sent,:) = [preamble_ext ... 
                                      access_address_bi ...
                                      00 ... % CI for S =8
                                      000 ... % TERM1
                                      pdu_corr_secondary{fragment_number}(nb_sent,:) ...
                                      000]; % TERM2

                full_packets_secondary{fragment_number}(nb_sent,:) = fec(full_packet_nfec_secondary{fragment_number}(nb_sent,:),ble_mode);  

                % Update time to wait before next packet
                total_time_interval_updated = total_time_interval - (time_between_ext_primaries + duration_ext_primary_packet);
                total_time_interval_chaining_updated = total_time_interval_chaining - (time_between_ext_secondaries + duration_max_ext_secondary_packet);
            end
            % Resetting the time to wait between 1st primary packet and 1st secondary packet
            total_time_interval_updated = total_time_interval;
            total_time_interval_chaining_updated = total_time_interval_chaining;
        end
    end
end


