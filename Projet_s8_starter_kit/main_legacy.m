clear 
close all 
clc 
dbstop if error 
%% Adding paths 
addpath("Bluetooth_functions/")
addpath("payload_processing_functions/")
addpath("Signal_processing_functions/")
%% Parameters 
channel_packet = 'Primary'; % choose if the packet is designed to be sent on a 'Primary' or 'Secondary channel'
packet_mode = 'Legacy';   % Set packet mode to 'Extended' (options: 'Legacy' or 'Extended')
ble_mode = 'LE1M'; 
default_CRC_init = '555555';         
sps = 8;
channel_index = 37; % channel to send the information on
length_preamble = 8; % in bits
length_access_address = 32; % in bits
Tb = 1; % bit duration

access_address_hex = {'8', 'E', '8', '9', 'B', 'E', 'D', '6'};
advA_hex = {'E','D', '8','8','3','C','9','B','B','6','D','B'}; % Fixed value for all BLE packets 
nb_bits_length_header = 8;
PDU_type = [0; 0; 0; 0];
RxAdd = 0;
TxAdd = 1;
Chsel = 1;
RFU = 0;
payload_hex = {'0', '2', '0', '1', '0', '6', '0', '8', '0', '9', '6', 'C', '6', '5', '6', 'F', '6', '2', '6', 'C', '7', '5', '6', '5'};
length_payload = (length(payload_hex)+length(advA_hex))/2; % This is the length definition in the case of legacy mode
length_payload_bits = get_payload_length(length_payload);

%% Defining the header and the PDU
new_header_LEG = [PDU_type; ...                         % PDU Type 0000 for ADV_IND
              RxAdd; ...                                % RxAdd (Receiver Address)
              TxAdd; ...                                % TxAdd (Transmitter Address)
              Chsel; ...                                % Chsel (Channel Selection)
              RFU; ...                                  % RFU (Reserved for Future Use)
              length_payload_bits];                     % Payload Length in bytes

advA = packet_bytes_to_bits(advA_hex); % Transforms the bytes into bits
payload = packet_bytes_to_bits(payload_hex);
access_address = AccessAddress_bytes_to_bits(access_address_hex);
preamble = preambleGenerator(ble_mode);
%% Generate header and append CRC 
data_to_send = generatePacketHeaderLegacy([advA;payload], new_header_LEG); % Concatenates the header to the packet                         % Default CRC initialization
sig_crc = add_crc(data_to_send, default_CRC_init);  % Append CRC to the packet
%% Whitening and adding preamble and access address 
whitened_bits = whitening_ble(sig_crc, channel_index);
bitstream_complete = [preamble; access_address; whitened_bits];

%% GMSK modulation
tx_waveform_new = GMSK_modulation(bitstream_complete,sps,Tb);
%% Save the generated waveform into a .bin file
filename_bin = saveSignalToFile(tx_waveform_new, ble_mode, packet_mode);    % Save signal to file
fprintf("The file %s has been successfully created\n\r", filename_bin); % Print confirmation


