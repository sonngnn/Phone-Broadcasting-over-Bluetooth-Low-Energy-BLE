clear 
close all 
clc 
dbstop if error 
%-------------------------Description--------------------------------------
% In this version, we consider the extended mode of Bluetooth, we will
% consider that all the payload is sent on the secondary channel and that
% the primary packet only contains instructions to be read on the secondary
% channel. You will have to complete this file and run tests
%--------------------------------------------------------------------------

%% Adding paths 
addpath("Bluetooth_functions/")
addpath("payload_processing_functions/")
addpath("Signal_processing_functions/")
%% Parameters
channel_packet = 'Primary'; % choose if the packet is designed to be sent on a 'Primary' or 'Secondary channel'
packet_mode = 'Extended';   % Set packet mode to 'Extended' (options: 'Legacy' or 'Extended')
ble_mode = 'LE1M'; 
data_rate = 1; % in Mbits/s
default_CRC_init = '555555';         
sps = 8;
primary_channel_index = 38;
secondary_channel_index = 9;
length_preamble = 8;
length_access_address = 32;
time_between_primary_and_secondary = 300; % in us
Tb = 1;

access_address_hex = {'8', 'E', '8', '9', 'B', 'E', 'D', '6'}; % Same defined for all Bluetooth packets
advA_hex = {'E','D', '8','8','3','C','9','B','B','6','D','B'};% Can be changed, we have to check how to get it back

PDU_type_primary = flipud([0;1;1;1]);
PDU_type_secondary = flipud([0;1;1;1]);

AdvMode_primary = flipud([0;0]); % for non connectable and non scannable
AdvMode_secondary = flipud([0;0]);

RxAdd_primary = 0;
TxAdd_primary = 0;
Chsel_primary = 1;
RFU_primary = 0;

RxAdd_secondary = 0;
TxAdd_secondary = 0;
Chsel_secondary = 0;
RFU_secondary = 0;
%--------------------------Extended Header Flags---------------------------
% AdvA      | TargetA  |   CTE    |   ADI    |  AuxPtr    |  SyncInfo  | TxPower  | RFU
% (6 bytes) | (6 bytes)|  (1 byte)| (2 bytes)| (3 bytes)  | (18 bytes) |  (1 byte)| 
%--------------------------------------------------------------------------
Ext_header_num_bytes = [6; 6; 1; 2; 3; 18; 1; 0];
Ext_header_flags_primary = [1; 0; 0; 1; 1; 0; 0; 0]; % presence of AdvA, ADI and auxPtr
Ext_header_flags_secondary = [0; 0; 0; 1; 0; 0; 0; 0]; % presence of ADI

%% Header and extended header length
payload_hex_primary = {}; % Empty because all data is sent on secondary channel 
%payload_hex_secondary = buildLegacyAdData();
payload_hex_secondary = {'0', '2', '0', '1', '0', '6'};

length_packet_primary = length(payload_hex_primary)/2 + 1 + 1 + sum(Ext_header_num_bytes.*Ext_header_flags_primary);
length_packet_bits_primary = get_payload_length(length_packet_primary); %convert to a vector of bits

length_packet_secondary = length(payload_hex_secondary)/2 + 1 + 1 + sum(Ext_header_num_bytes.*Ext_header_flags_secondary);
length_packet_bits_seconday = get_payload_length(length_packet_secondary); %convert to a vector of bits

length_ext_header_primary = sum(Ext_header_num_bytes.*Ext_header_flags_primary) +1; % 1 byte for the extended header flag
length_ext_header_primary_bits = get_ext_header_length(length_ext_header_primary);

length_ext_header_secondary = sum(Ext_header_num_bytes.*Ext_header_flags_secondary) + 1;
length_ext_header_secondary_bits = get_ext_header_length(length_ext_header_secondary);

%% Computing the overall time of the primary packet (this is useful afterwards for the definition of the AuxPtr field)
nb_bits_primary_packet = (length_packet_primary + 1 + 4 + 1 + 1 + 3) * 8; % 1 byte for preamble, 4 for access address, 1 for PDUtype and co, 1 for length and 3 for CRC
duration_primary_packet = nb_bits_primary_packet/ data_rate; % in us because the offset unit is in us
total_time_interval = duration_primary_packet + time_between_primary_and_secondary;
%% Access address to bits 
access_address = AccessAddress_bytes_to_bits(access_address_hex);
%% Generate preamble 
preamble = preambleGenerator(ble_mode);

%% Defining the header
header_EXT_primary = [PDU_type_primary; ...                     % PDU Type 
              RxAdd_primary; ...                                % RxAdd (Receiver Address)
              TxAdd_primary; ...                                % TxAdd (Transmitter Address)
              Chsel_primary; ...                                % Chsel (Channel Selection)
              RFU_primary; ...                                  % RFU (Reserved for Future Use)
              length_packet_bits_primary];                     % Payload Length in bytes

header_EXT_secondary = [PDU_type_secondary; ...                   % PDU Type 
              RxAdd_secondary; ...                                % RxAdd (Receiver Address)
              TxAdd_secondary; ...                                % TxAdd (Transmitter Address)
              Chsel_secondary; ...                                % Chsel (Channel Selection)
              RFU_secondary; ...                                  % RFU (Reserved for Future Use)
              length_packet_bits_seconday];                     % Payload Length in bytes

%% Defining the extended header
ext_header_EXT_primary = [length_ext_header_primary_bits; AdvMode_primary ];
ext_header_EXT_secondary = [length_ext_header_secondary_bits; AdvMode_secondary ];
%% Defining the extended header elements for primary channel
advA_primary = packet_bytes_to_bits(advA_hex);
TargetA_primary = []; % To be defined for future versions
CTE_primary = [];
ADI_primary = zeros(16,1); % see more on what it means and how to define it 

%---------------------------------AuxPtr-----------------------------------
% Channel index |  CA   | Offset Units | AUX offset | AUX Phy
%   (6 bits)    |(1 bit)|  (1 bit)     |  (13 bits) | (3 bits)
%--------------------------------------------------------------------------
% Channel index
auxptr_channel_index = get_ext_header_length(secondary_channel_index); % we consider the secondary channel index 
% CA 
auxtr_CA = 1; % dig deeper to see what it represents
% Offset Units
auxptr_offset_units = 0; % 30us if 0 and 300us if 1
if auxptr_offset_units == 0
    auxptr_offset_units_us = 30;
else
    auxptr_offset_units_us = 300;
end
% AUX offset
AUX_offset = floor(total_time_interval/auxptr_offset_units_us) -1 ;
auxptr_AUX_offset = flipud(int2bit(AUX_offset,13));

% AUX Phy
auxptr_phy = flipud([0;0;0]); % [0 0 0] for 1M, [0 0 1] for 2M and [0 1 0] for CODED

auxptr_primary = [auxptr_channel_index; auxtr_CA; auxptr_offset_units; auxptr_AUX_offset; auxptr_phy];
%--------------------------------------------------------------------------
%----------------------------SyncInfo--------------------------------------
syncinfo_primary = []; % To be defined for chained data
%--------------------------------------------------------------------------
txpower_primary = [];
rfu_primary = [];
%% Defining the extended header elements for secondary channel
advA_secondary = [];
TargetA_secondary = []; % To be defined for future versions
CTE_secondary = [];
ADI_secondary = zeros(16,1); % see more on what it means and how to define it 
auxptr_secondary = [auxptr_channel_index; auxtr_CA; auxptr_offset_units; auxptr_AUX_offset; auxptr_phy];
syncinfo_secondary = []; % To be defined for chained data
txpower_secondary = [];
rfu_secondary = [];
%% Structure containing all fields for primary and secondary
extHeaderFieldsStructPrimary = struct();
extHeaderFieldsStructPrimary.advA = advA_primary; 
extHeaderFieldsStructPrimary.targetA = TargetA_primary;          
extHeaderFieldsStructPrimary.cte = CTE_primary;  
extHeaderFieldsStructPrimary.ADI = ADI_primary;          
extHeaderFieldsStructPrimary.auxptr = auxptr_primary;           
extHeaderFieldsStructPrimary.syncinfo = syncinfo_primary;
extHeaderFieldsStructPrimary.txPower = txpower_primary;
extHeaderFieldsStructPrimary.rfu = rfu_primary;


extHeaderFieldsStructSecondary = struct();
extHeaderFieldsStructSecondary.advA = advA_secondary; 
extHeaderFieldsStructSecondary.targetA = TargetA_secondary;          
extHeaderFieldsStructSecondary.cte = CTE_secondary;  
extHeaderFieldsStructSecondary.ADI = ADI_secondary;          
extHeaderFieldsStructSecondary.auxptr = auxptr_secondary;           
extHeaderFieldsStructSecondary.syncinfo = syncinfo_secondary;
extHeaderFieldsStructSecondary.txPower = txpower_secondary;
extHeaderFieldsStructSecondary.rfu = rfu_primary;
%% Defining the AdvData
payload_bits_primary = packet_bytes_to_bits(payload_hex_primary);
payload_bits_secondary = packet_bytes_to_bits(payload_hex_secondary);

%% Generate header, extended header and append CRC 
data_to_send_primary = buildExtendedPDU(header_EXT_primary, ext_header_EXT_primary, extHeaderFieldsStructPrimary, Ext_header_flags_primary, payload_bits_primary);
sig_crc_primary = add_crc(data_to_send_primary, default_CRC_init);  % Append CRC to the packet

data_to_send_secondary = buildExtendedPDU(header_EXT_secondary, ext_header_EXT_secondary, extHeaderFieldsStructSecondary, Ext_header_flags_secondary, payload_bits_secondary);
sig_crc_secondary = add_crc(data_to_send_secondary, default_CRC_init);  % Append CRC to the packet


%% Whitening and adding preamble and access address 
whitened_bits_primary = whitening_ble(sig_crc_primary, primary_channel_index);
bitstream_complete_primary = [preamble; access_address; whitened_bits_primary];

whitened_bits_secondary = whitening_ble(sig_crc_secondary, secondary_channel_index);
bitstream_complete_secondary = [preamble; access_address; whitened_bits_secondary];

%% GMSK modulation
tx_waveform_primary = GMSK_modulation(bitstream_complete_primary,sps,Tb);
tx_waveform_secondary = GMSK_modulation(bitstream_complete_secondary,sps,Tb);

%% Save the iq in a .bin file 
% To complete. Here you have to consider either sending on one frequency
% and therefore adjusting one of the signals or having a function that
% first sends the primary packet on the associated frequency and then the
% secondary packet.