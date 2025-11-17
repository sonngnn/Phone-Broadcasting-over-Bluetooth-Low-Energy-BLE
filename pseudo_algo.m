%% Pseudo algo pour chaîne de comm
% fonctions pas faites, préallocations pas faites...
%% Paramètres

data_rate = 1; % in Mbits/s
%sps = 8;
time_between_primary_and_secondary = 300; % in us
time_between_ext_primaries = 20; % in us
time_between_ext_secondaries = 20; % in us
%Tb = 1;
primary_channel_index = 37;

% Paramètres
fc = 2.402e9; % Fréquence du canal primaire 37 (2,402 GHz)
Fs = 10e6;  % Fréquence d'échantillonnage (10 MHz)
Tb = 1e-6;  % Durée d'un bit (1 µs pour un débit de 1 Mbit/s)
sps = 8;    % Nombre d'échantillons par symbole


%% Réception & fragmentation du fichier initial

% Utilisateur choisit les options voulues
file_to_send = ask_user("filename"); % Demande à l'utilisateur quel fichier il veut envoyer

packet_mode = ask_user("packet_mode"); % Utilisateur choisit Extended / Legacy

ble_mode = ask_user("ble_mode"); % Utilisateur choisit 1M/125k

send_strategy = ask_user("strategy"); % Utilisateur choisit quelle stratégie employer pour envoyer données en Extended (primaire, primaire/secondaire, chainée)
% Chainée pas traitée pour le moment
if send_strategy == 2
    selected_channel = ask_user("channel"); % Demande à l'utilisateur sur quel canal secondaire il veut envoyer la data
    selected_channel_bi = de2bi(selected_channel,6,"right-msb");
end

advA = ask_user("Address"); % Demande à l'utilisateur l'adresse qu'il veut indiquer dans les trames
advA_bi = he2bi(advA); % Converti en binaire l'adresse avec bon MSB...

multiple_send = ask_user("multiple"); % Demande à l'utilisateur combien de fois les paquets doivent-ils être envoyés pour s'assurer de la réception ?

% Vérification que les options soient valables dans la fonction ask_user..., on peut faire une fct/demande pour gérer les options de réponses

% Convertion en bitstream + fragmentation
[bitstream_to_send, data_type] = convert_file(file_to_send); % Converti le fichier en flux binaire avec l'algo correct en fct du type de fichier + renvoi type du fichier (jsp si fait ici ou autre part...)
% data_type de la forme : 00 si texte, 01 si audio, 10 si image, 11 si vidéo 

bitstream_auth_to_send = auth(bitstream_to_send); % Ajoute la partie authentification à la fin du bitstream

fragments = fragmentation(bitstream_auth_to_send,packet_mode,ble_mode, send_strategy); % Fragmente le bitstream en plusieurs paquets en fct des modes choisis
% Utiliser size(fragments,1) plutot que length car matrice..
%% Préparation headers
% Pas ultra clean la manière dont c'est fait... mais il faut garder des
% headers évolutifs car certains changent à chaque paquet

header_legacy = [ 0 0 1 0 ... % PDU Type 0010 for ADV_NON_CONN
    0 ... % RFU
    0 ... % ChSel = Algorithme simple de Frequency Hopping
    0 ... % TxAdd = Adresse Publique pour émetteur
    0]; % RxAdd = Adresse Publique pour récepteur

header_extended_wo_length = [0 1 1 1 ... % PDU TYPE pour ADV_EXT_IND, AUX_ADV_IND et AUX_CHAIN_IND
    0 ... % RFU = Bit non utilisé
    0 ... % Chsel = Algorithme simple de Frequency Hopping
    0 ... % TxAdd = Adresse Publique pour émetteur
    0]; % RxAdd = Adresse Publique pour récepteur

ext_header_advA = [1 1 1 0 0 0 ... % Taille de l'extended header : 7 octets
    0 0 ... % advMode en non-connectable et non-scannable
    1 0 0 0 0 0 0 0 ...
    advA]; % Extended Header Flags que pour AdvA

if send_strategy == 2 || send_strategy == 3
    ext_header_ADI = [0 0 1 0 0 0 ... % Taille de l'extended header : 4 octets
                            0 0 ... % advMode en non-connectable et non-scannable
                            0 0 0 1 0 0 0 0]; % Extended Header Flags pour ADI (identification d'un paquet)
    % Les champs d'ADI se rempliront au fil des trames envoyés

    ext_header_advA_ADI_AuxPtr = [0 1 0 1 0 0 ...% 13 octets
        0 0 ...
        1 0 0 1 1 0 0 0 ...
        advA];% Extended Header Flags pour AdvA, ADI AuxPtr (canal primaire)

    if send_strategy == 3
        % Paquet chainée (1er : primary 2e: secondary 3-8e :secondary (pas
        % dépasser 1650 octets dans la chaine)
        % ext_header_adi utilisé pour dernier paquet de la chaine, il faut
        % faire ceux ayant champs ADI et AuxPtr

        ext_header_ADI_AuxPtr = [0 1 1 0 0 0 ... % Taille de l'extended header : 6 octets
                            0 0 ... % advMode en non-connectable et non-scannable
                            0 0 0 1 1 0 0 0 ...
                            ]; % ADI avant AuxPtr donc on ne peut rien remplir actuellement
    end

end
% A l'issue de la préparation : il manque la taille du payload et remplir
% le champ AuxPtr ce qui doit se faire à chaque paquet envoyé puisque dans
% le cas d'un envoi multiple, le dernier paquet n'aura pas le même temps
% d'attente que le premier

preambule_legacy = 10101010; % Préambule du legacy
preamble_ext = rep(00111100,10); % Préambule pour l'extended qui est répété 10 fois

% A supprimer apres, uniquement pour test synchro/demod Préambule GMSK en bande de base (utile pour synchro)
preamble_bits = [1 0 1 0 1 0 1 0];  % même que preambule_legacy
preamble_bb = gmsk(preamble_bits, sps, Tb);  % bande de base

_address = hex2bi("8E89BaccessED6"); 
%% Définir temps/trame pour AuxPtr

nb_bytes_ext_primary_packet = 1 + 4 + 2 + 1 + 1 + 6 + 3 + 3; % Préambule + AA + header + Extended header length+advMode + ExtFlags + AdvA + AuxPtr + CRC 
duration_ext_primary_packet = nb_bytes_ext_primary_packet / data_rate;
total_time_interval = (duration_ext_primary_packet+time_between_ext_primaries)*multiple_send + time_between_primary_and_secondary;
total_time_interval_updated = total_time_interval; % Afin de garder la variable total_time puisqu'elle va être réutilisée

% Pour paquet chainé, il faut définir le temps d'un paquet sur canal
% secondaire  pour faire l'attente jusqu'aux nouveaux paquets de la chaîne
% On peut considérer que tous les paquets sont remplis et différencier
% Coded/Uncoded
if ble_mode == "1M"
    nb_bytes_max_ext_secondary_packet = 1+4+2+1+255+3; %Préambule + AA + header + ext_header(flags+advmode) + AdvData complet + CRC (champs du ext_header remplis mais ne change pas nbre d'octet tot car prend sur AdvData)
else
    nb_bytes_max_ext_secondary_packet = 10 + (4 + 1 + 2 + 1 + 254 + 3)*8; % Idem qu'avant mais terme CI+Term1+Term2, préambule plus long et codage en S=8 donc *8 chaque octet
end
 
duration_max_ext_secondary_packet = nb_bytes_max_ext_secondary_packet / data_rate;
total_time_interval_chaining = (duration_max_ext_secondary_packet+time_between_ext_secondaries)*multiple_send + time_between_ext_secondaries; % Temps que tous les secondaires soient énvoyés + durée entre 2 paquets secondaires pour le chaining
total_time_interval_chaining_updated = total_time_interval_chaining;
%% Création trames
if packet_mode == "Legacy"
    for i = 1:multiple_send:length(fragments)*multiple_send
        nb_frag = i/multiple_send; % n-ième paquet
        nb_frag_bi = de2bi(nb_frag,9,"right-msb");

        for j=1:multiple_send
                user_data = fragments(nb_frag);
                %ad_structure = [user_data_length, 0xFF, user_data];

            % On complète adData avec les infos sur le paquet actuel
            nb_sent = de2bi(j,4,"right-msb");
            if j==multiple_send
                adData_leg(i+j-1) = [nb_frag ... % n-ième paquet envoyé
                    nb_sent ... % n-ième fois que ce paquet est envoyé
                    1 ... % dernière fois que ce paquet est envoyé
                    data_stream_type ... % type SMS, vidéo, etc...
                    % ci-dessus : correspond à 2 octets
                    user_data];
                user_data_length = length(adData_leg(i+j-1));
            else
                adData_leg(i+j-1) = [nb_frag nb_sent 0 data_stream_type user_data];
                user_data_length = length(adData_leg(i+j-1));
            end

            % AD structure 1 = advData_leg (ccar une seule ad structure
            advData_leg(i+j-1) = [user_data_length 0xFF adData_leg(i+j+1)]; % avec 0xFF le AD type de taille 1 octets
                % company id fortement recommndé 0xFF 0x12 0x34 données utiles...
            payload_leg(i+j-1) = [advA advData_leg(i)]; 
            length_payload_leg = de2bi(length(payload(i+j-1)),8,"right-msb");

            pdu_leg(i+j-1) = [header_legacy length_payload_leg payload_leg(i+j-1)]; % PDU avec header indiquant le type extended 

            pdu_corr(i+j-1) = CRC(whitening(pdu_leg(i+j-1))); % Fait le Whitening puis le CRC sur le PDU

            full_packet(i+j-1) = [preamble_legacy access_address pdu_corr(i+j-1)];

<<<<<<< HEAD
            full_packet_modulated_primary(i+j-1) = gmsk(full_packet(i+j-1),sps,Tb); % Modulation GMSK sur les paquets
=======
            full_packet_modulated(i+j-1) = gmsk(full_packet(i+j-1)); % Modulation GMSK sur les paquets
>>>>>>> 12a5729696c91202afaa03c1a1b7379331961c79
        end
    end
else 
    % packet_mode == "Extended"
    if send_strategy == 1
        for i=1:multiple_send:length(fragments)*multiple_send % Nombre de trame total qui va être envoyée (avec les répétitions), chaque multiple_send correspond à une nouvelle trame
            nb_frag = floor(i/multiple_send); % n-ième paquet
            nb_frag_bi = de2bi(nb_frag,9,"right-msb");
               
            for j=1:multiple_send
                % On complète advData avec les infos sur le paquet actuel
                nb_sent = de2bi(j,4,"right-msb");
                if j==multiple_send
                    advData(i+j-1) = [nb_frag ... % n-ième paquet envoyé
                                      nb_sent ... % n-ième fois que ce paquet est envoyé
                                      1 ... % dernière fois que ce paquet est envoyé
                                      data_type ... 
                                      fragments(nb_frag)];  
                else
                    advData(i+j-1) = [nb_frag nb_sent 0 data_type fragments(nb_frag)];
                end
    
                payload(i+j-1) = [ext_header_advA advData(i+j-1)]; % Rajout de l'extended header sans AuxPtr car stratégie 1
                
                % Calcul taille payload pour header
                length_payload = de2bi(length(payload(i+j-1)),8,"right-msb");

                pdu(i+j-1) = [header_extended_wo_length length_payload payload(i+j-1)]; % PDU avec header indiquant le type extended 

                pdu_corr(i+j-1) = whitening(CRC(pdu(i+j-1)),primary_channel_index); % Fait le CRC puis le Whitening sur le PDU
                
                if ble_mode == "1M"
                    full_packet(i+j-1) = [preamble_ext access_address pdu_corr(i+j-1)];
                else % ble_mode == 125k
                    full_packet_nfec(i+j-1) = [preamble_ext ... 
                                          access_address ...
                                          00 ... % CI pour S =8
                                          000 ... % TERM1
                                          pdu_corr(i+j-1) ...
                                          000]; % TERM2
                    full_packet(i+j-1) = fec(full_packet_nfec(i+j-1)); % Fais le FEC du paquet (/!\ préambule pas codé par FEC)
                end
                full_packet_modulated_primary(i+j-1) = gmsk(full_packet(i+j-1),sps,Tb); % Modulation GMSK sur les paquets
           end
               
       end

    elseif send_strategy == 2
        % On répète multiple_send fois sur canal primaire et multiple_send fois sur canal secondaire ?
        % A chaque paquet est associée un header sur canal primaire avec
        % champ AdvA et AuxPtr qui redirige vers secondaire
        for i=1:multiple_send:length(fragments)*multiple_send
            nb_frag = floor(i/multiple_send); % n-ième paquet
            nb_frag_bi = de2bi(nb_frag,9,"right-msb");
               
            for j=1:multiple_send
                % On complète advData avec les infos sur le paquet actuel
                nb_sent = de2bi(j,4,"right-msb");
                if j==multiple_send
                    advData_primary(i+j-1) = [nb_frag ... % n-ième paquet envoyé
                                      nb_sent ... % n-ième fois que ce paquet est envoyé
                                      1 ... % dernière fois que ce paquet est envoyé
                                      data_type]; % Pas de donnéees utiles dans le primary, juste le champ AuxPtr sera rempli
                    
                    advData_secondary(i+j-1) = [nb_frag ... % n-ième paquet envoyé
                                      nb_sent ... % n-ième fois que ce paquet est envoyé
                                      1 ... % dernière fois que ce paquet est envoyé
                                      data_type ... 
                                      fragments(nb_frag)];  
                else
                    advData_primary(i+j-1) = [nb_frag nb_sent 0 data_type];
                    advData_secondary(i+j-1) = [nb_frag nb_sent 0 data_type fragments(nb_frag)];
                end
                % Calcul les champs à remplir pour AuxPtr (mise à jour du
                % temps à attendre)
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
                
                DID = bi2de(nb_frag,12,"right-msb"); % Identifiant pour chaque paquet différent
                SID = [0 0 0 0]; % Identifiant d'un envoi de données (?)

                ext_header_advA_ADI_AuxPtr_filled = [ext_header_advA_ADI_AuxPtr DID SID selected_channel_bi 1 auxptr_offset_units AUX_offset auxptr_phy];
                ext_header_ADI_filled = [ext_header_ADI DID SID];

                payload_primary(i+j-1) = [ext_header_advA_ADI_AuxPtr_filled advData_primary(i+j-1)]; % Rajout de l'extended header avec AuxPtr car stratégie 2
                payload_secondary(i+j-1) = [ext_header_ADI_filled advData_secondary(i+j-1)]; % Rajout de l'extended header sans AuxPtr car sur secondary et pas chainée

                % Calcul taille payload pour header
                length_payload_primary = de2bi(length(payload_primary(i+j-1)),8,"right-msb");
                length_payload_secondary = de2bi(length(payload_secondary(i+j-1)),8,"right-msb");

                pdu_primary(i+j-1) = [header_extended_wo_length length_payload_primary payload_primary(i+j-1)]; % PDU avec header indiquant le type extended 
                pdu_secondary(i+j-1) = [header_extended_wo_length length_payload_secondary payload_secondary(i+j-1)]; % PDU avec header indiquant le type extended 

                pdu_corr_primary(i+j-1) = whitening(CRC(pdu_primary(i+j-1)),primary_channel_index); % Fait le Whitening puis le CRC sur le PDU
                pdu_corr_secondary(i+j-1) = whitening(CRC(pdu_secondary(i+j-1)),selected_channel); % Fait le Whitening puis le CRC sur le PDU
                
                if ble_mode == "1M"
                    full_packet_primary(i+j-1) = [preamble_ext access_address pdu_corr_primary(i+j-1)];
                    full_packet_secondary(i+j-1) = [preamble_ext access_address pdu_corr_secondary(i+j-1)];
                else % ble_mode == 125k
                    full_packet_nfec_primary(i+j-1) = [preamble_ext ... 
                                                      access_address ...
                                                      00 ... % CI pour S =8
                                                      000 ... % TERM1
                                                      pdu_corr_primary(i+j-1) ...
                                                      000]; % TERM2
                    full_packet_nfec_secondary(i+j-1) = [preamble_ext ... 
                                                              access_address ...
                                                              00 ... % CI pour S =8
                                                              000 ... % TERM1
                                                              pdu_corr_secondary(i+j-1) ...
                                                              000]; % TERM2
        
                    full_packet_primary(i+j-1) = fec(full_packet_nfec_primary(i+j-1)); % Fais le FEC du paquet (/!\ préambule pas codé par FEC)
                    full_packet_secondary(i+j-1) = fec(full_packet_nfec_secondary(i+j-1)); % Fais le FEC du paquet (/!\ préambule pas codé par FEC)
                end
                full_packet_modulated_primary(i+j-1) = gmsk(full_packet_primary(i+j-1),sps,Tb); % Modulation GMSK sur les paquets
                full_packet_modulated_secondary(i+j-1) = gmsk(full_packet_secondary(i+j-1),sps,Tb); % Modulation GMSK sur les paquets

                % Mise à jour temps à attendre avant prochain paquet
                total_time_interval_updated = total_time_interval - (time_between_ext_primaries + duration_ext_primary_packet);
            end
            % Remise à zéro du temps à attendre entre 1er paquet primaire
            % et 1er paquet secondaire
            total_time_interval_updated = total_time_interval;
        end


    else % chainée
        for i=1:multiple_send:length(fragments)*multiple_send
            nb_frag = floor(i/multiple_send); % n-ième paquet
            nb_frag_bi = de2bi(nb_frag,9,"right-msb");
            for j=1:multiple_send
                % On complète advData avec les infos sur le paquet actuel
                nb_sent = de2bi(j,4,"right-msb");
                
                if mod(nb_frag,6) == 1 % Paquet chainé n'a besoin d'un header primaire qu'un paquet sur 6
                    if j==multiple_send
                        % L'indexage marche vrmt ?
                        advData_primary(ceil(i/6)+j-1) = [nb_frag ... % n-ième paquet envoyé
                                      nb_sent ... % n-ième fois que ce paquet est envoyé
                                      1 ... % dernière fois que ce paquet est envoyé
                                      data_type]; % Pas de donnéees utiles dans le primary, juste le champ AuxPtr sera rempli
                    else
                        advData_primary(ceil(i,6)+j-1) = [nb_frag nb_sent 0 data_type];
                    end
                end

                if j==multiple_send
                    advData_secondary(i+j-1) = [nb_frag ... % n-ième paquet envoyé
                                      nb_sent ... % n-ième fois que ce paquet est envoyé
                                      1 ... % dernière fois que ce paquet est envoyé
                                      data_type ... 
                                      fragments(nb_frag)];  
                else
                    advData_secondary(i+j-1) = [nb_frag nb_sent 0 data_type fragments(nb_frag)];
                end

                % Calcul les champs à remplir pour AuxPtr (mise à jour du
                % temps à attendre)
                % Offset Units

                if mod(nb_frag,6) == 1
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
                    
                    DID = bi2de(nb_frag,12,"right-msb"); % Identifiant pour chaque paquet différent
                    SID = [0 0 0 0]; % Identifiant d'un envoi de données (?)

                    ext_header_advA_ADI_AuxPtr_filled_primary = [ext_header_advA_ADI_AuxPtr DID SID selected_channel_bi 1 auxptr_offset_units_primary AUX_offset_primary auxptr_phy_primary];
                    payload_primary(ceil(i/6)+j-1) = [ext_header_advA_ADI_AuxPtr_filled advData_primary(ceil(i/6)+j-1)]; % Rajout de l'extended header avec AuxPtr car stratégie 2

                    length_payload_primary = de2bi(length(payload_primary(ceil(i/6)+j-1)),8,"right-msb");
                    pdu_primary(ceil(i/6)+j-1) = [header_extended_wo_length length_payload_primary payload_primary(ceil(i/6)+j-1)]; % PDU avec header indiquant le type extended 
                    pdu_corr_primary(ceil(i/6)+j-1) = whitening(CRC(pdu_primary(ceil(i/6)+j-1)),primary_channel_index); % Fait le Whitening puis le CRC sur le PDU
                    if ble_mode == "1M"
                        full_packet_primary(ceil(i/6)+j-1) = [preamble_ext access_address pdu_corr_primary(ceil(i/6)+j-1)];
                    else % ble_mode == 125k
                        full_packet_nfec_primary(ceil(i/6)+j-1) = [preamble_ext ... 
                                                      access_address ...
                                                      00 ... % CI pour S =8
                                                      000 ... % TERM1
                                                      pdu_corr_primary(ceil(i/6)+j-1) ...
                                                      000]; % TERM2
                        full_packet_primary(ceil(i/6)+j-1) = fec(full_packet_nfec_primary(ceil(i/6)+j-1)); % Fais le FEC du paquet (/!\ préambule pas codé par FEC)

                    end
                    full_packet_modulated_primary(ceil(i/6)+j-1) = gmsk(full_packet_primary(ceil(i/6)+j-1),sps,Tb); % Modulation GMSK sur les paquets

                    
                end
                
                if nb_frag == length(fragments) || mod(nb_frag,6) == 0
                    % Dans ce cas, pas de champ AuxPtr car fin de chaîne
                    DID = bi2de(nb_frag,12,"right-msb"); % Identifiant pour chaque paquet différent
                    SID = [0 0 0 0]; % Identifiant d'un envoi de données (?)

                    ext_header_ADI_filled = [ext_header_ADI DID SID];
    
                    payload_secondary(i+j-1) = [ext_header_ADI_filled advData_secondary(i+j-1)];


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
                    
                    DID = bi2de(nb_frag,12,"right-msb"); % Identifiant pour chaque paquet différent
                    SID = [0 0 0 0]; % Identifiant d'un envoi de données (?)

                    ext_header_ADI_AuxPtr_filled = [ext_header_ADI_AuxPtr DID SID selected_channel_bi 1 auxptr_offset_units_secondary AUX_offset_secondary auxptr_phy_secondary];
    
                    payload_secondary(i+j-1) = [ext_header_ADI_AuxPtr_filled advData_secondary(i+j-1)]; 

                end
                
                % Calcul taille payload pour header
                
                length_payload_secondary = de2bi(length(payload_secondary(i+j-1)),8,"right-msb");

                pdu_secondary(i+j-1) = [header_extended_wo_length length_payload_secondary payload_secondary(i+j-1)]; % PDU avec header indiquant le type extended 

                pdu_corr_secondary(i+j-1) = whitening(CRC(pdu_secondary(i+j-1)),selected_channel); % Fait le Whitening puis le CRC sur le PDU
                
                if ble_mode == "1M"
                    full_packet_secondary(i+j-1) = [preamble_ext access_address pdu_corr_secondary(i+j-1)];
                else % ble_mode == 125k
                    full_packet_nfec_secondary(i+j-1) = [preamble_ext ... 
                                                              access_address ...
                                                              00 ... % CI pour S =8
                                                              000 ... % TERM1
                                                              pdu_corr_secondary(i+j-1) ...
                                                              000]; % TERM2
        
                    full_packet_secondary(i+j-1) = fec(full_packet_nfec_secondary(i+j-1)); % Fais le FEC du paquet (/!\ préambule pas codé par FEC)
                end
                full_packet_modulated_secondary(i+j-1) = gmsk(full_packet_secondary(i+j-1),sps,Tb); % Modulation GMSK sur les paquets

                % Mise à jour temps à attendre avant prochain paquet
                total_time_interval_updated = total_time_interval - (time_between_ext_primaries + duration_ext_primary_packet);
                total_time_interval_chaining_updated = total_time_interval_chaining - (time_between_ext_secondaries + duration_max_ext_secondary_packet);

            end
            total_time_interval_updated = total_time_interval;
            total_time_interval_chaining_updated = total_time_interval_chaining;
        end


    end
end
%% Envoi des trames

% On choisit canal primaire 37

fp = (2402 + (primary_channel_index*2)) * 10^6; % Fréquence porteuse en Hz

% faire espacement temporel entre envois...



% Dépend stratégie utilisée (1ere trame sur primaire puis reste sur
% secondaire, bien gérer décalage temporel)







% Génération d'un flux binaire aléatoire
input_bits = randi([0 1], 1, 100); % 100 bits aléatoires

% Modulation GMSK
signal_gmsk = gmsk(input_bits, sps, Tb);

% Mise sur fréquence porteuse
signal_rf = mise_sur_frequence_porteuse(signal_gmsk, fc, Fs);





% Séquence de saut de fréquence (exemple : canaux 37, 0, 38, 1, 39, 2)
hop_sequence = [37, 0, 38, 1, 39, 2];

% Intervalle de saut (625 µs, comme dans le Bluetooth classique)
hop_interval = 625e-6;

% Frequency Hopping
frequency_hopping_ble(signal_rf, Fs, hop_sequence, hop_interval);







% Visualisation du signal en bande de base et en bande passante
t = (0:length(signal_gmsk)-1) / Fs;

figure;
subplot(2, 1, 1);
plot(t, real(signal_gmsk));
title('Signal GMSK en bande de base (partie réelle)');
xlabel('Temps (s)');
ylabel('Amplitude');

subplot(2, 1, 2);
plot(t, signal_rf);
title('Signal GMSK sur fréquence porteuse');
xlabel('Temps (s)');
ylabel('Amplitude');



%signal_received = signal_rf + bruit;
signal_received = signal_rf;

% Synchronisation temporelle spécifique GMSK
[delta, ~] = synchro_gmsk(signal_received, preamble_bb);

% Découpage du signal pour ne garder que les données après le préambule
signal_synchro = signal_received(delta + length(preamble_bb):end);

% Démodulation GMSK du signal synchronisé
bits_recus = demod_gmsk(signal_synchro, fc, Fs, sps, Tb);

% Comparaison avec bits envoyés
disp("Bits transmis :");
disp(input_bits);
disp("Bits reçus :");
disp(bits_recus(1:length(input_bits)));  % Tronquage si besoin
