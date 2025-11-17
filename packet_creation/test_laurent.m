%% Packet creation for Bluetooth
addpath("../transmission_image/")
addpath("../Transmission_audio/")
addpath("./Bluetooth_functions/")
addpath("./creation_trame/")
addpath("./fonction_annexe/")
addpath("./fonction_fichier/")

clear
clc
close all

%% Parameters

% Pre-defined Parameters

data_rate = 1e6; % 1 Mbits/s
sps = 8;
time_between_primaries = 0.005; % in s
Tb = 1;
primary_channel_index = 37;
secondary_channel_index = 9;
length_ext_frag_max = 255;


% Parameters defined by the user

%file_to_send = ask_user("filename"); % Choose a file to send (image/audio/video/text)
file_to_send = "filename";

%packet_mode = ask_user("packet_mode"); % Extended / Legacy
packet_mode = "Legacy";

ble_mode = '1M';
send_strategy = 'primary';

%discoverable_flag = ask_user("discoverable"); % Decide if the first ADStructure is 02 01 06
discoverable_flag = "N";

%name_flag = ask_user("name_flag"); % Decide if the '09' structure (name) is in the bitstream
name_flag = "N";
name = [];
if strcmp(name_flag, "Y") == 1
    name = ask_user("name");
end

%SIG = ask_user("SIG");
SIG = 4677;

%advA_bi = ask_user("address"); % AdvA used in headers converted in binary
advA_bi = [0 1 0 1 0 1 0 1 1 1 0 1 1 1 0 1 0 0 1 1 0 0 1 1 1 0 1 1 1 0 1 1 0 1 1 1 0 1 1 1 1 1 1 1 1 1 1 1]; % AABBCCDDEEFF

%multiple_send = ask_user("multiple"); % How many times a packet must be sent to guarantee a good receipt
multiple_send = 10;

%unique_binary_file = ask_user("unique_binary_file"); % If we transfer the data through 1 or multiple binary file
unique_binary_file = "Y";

%entrelacage = ask_user("entrelacage");
entrelacage = "Y";

%mobile = ask_user("mobile"); % Reception with mobile (Laurent)
mobile = "Y";

notif = "N";

if strcmp(mobile,"Y") == 1
    %notif = ask_user("notif");
    notif = "N"; % Changer ici si Y/N
end

%% Before creating the packets

% Convert in bitstream
%[bitstream_to_send, data_type] = convert_file(file_to_send); % Convert the file to a binary stream with the correct algorithm depending of the data type + return data type
% data_type : 00 if text, 10 if audio, 01 if image, 11 if vidéo 

%bitstream_auth_to_send = auth(bitstream_to_send); % Add the authentication part to the end of the bitstream
%bitstream_auth_to_send = bitstream_to_send;
% Fragmentation
%fragments = fragmentation(bitstream_auth_to_send,packet_mode,ble_mode, send_strategy, length_ext_frag_max, discoverable_flag, name_flag, name, notif); % Fragments the bitstream into several packets depending on the chosen modes

data_type = [0 0 0 0 0 0 0 0];
nb_rep = 500;
for rep=1:nb_rep
    fragments{rep} = randi([0,1],1,1736);
end

%fragments{1} = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];
%fragments{2} = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
%% Creating packets

if strcmp(packet_mode,"Legacy") == 1
    if strcmp(mobile,"Y") == 1
        packets = create_packet_legacy_mobile(fragments, primary_channel_index, advA_bi, multiple_send, data_type, name_flag, name, discoverable_flag, SIG, notif);
    else
        packets = create_packet_legacy(fragments, primary_channel_index, advA_bi, multiple_send, data_type, name_flag, name, discoverable_flag, SIG);
    end
end


%% Modulation

packets_modulated = preallocating_cell(length(packets),multiple_send, 15488, 15488);

if strcmp(packet_mode,"Legacy") == 1
     if strcmp(mobile,"Y") == 1
        for idx = 1:length(packets)
            packets_modulated{idx}(1,:) = GMSK_modulation(packets{idx}(1,:).',sps,Tb);
            for rep = 2:multiple_send
                packets_modulated{idx}(rep,:) = packets_modulated{idx}(1,:);
            end
        end

     else
        for idx = 1:length(packets)
            for nb_sent = 1:multiple_send
                packets_modulated{idx}(nb_sent,:) = GMSK_modulation(packets{idx}(nb_sent,:).',sps,Tb);
            end
        end
     end
end

%% Saving file

if strcmp(packet_mode,"Legacy") == 1
    saveSignalToFile(packets_modulated,ble_mode,packet_mode,unique_binary_file,time_between_primaries,data_rate,sps, multiple_send,mobile, entrelacage);  
end


fprintf("Tous les fichiers ont été créé \n")
