function fragments = fragmentation(bitstream, packet_mode, ble_mode, send_strategy, length_ext_frag_max, discoverable_flag, name_flag, name, notif)

    % Convert the initial bitstream into several fragments (if needed)
    % depending on the chosen mode and strategy
    total_length = length(bitstream);
    
    % Define maximum payload sizes
    if strcmp(notif,"Y") == 1
        legacy_length_max = 32 * 8;
    else
        legacy_length_max = 227 * 8;
    end
     % 31 octets = 248 bits //// prendre en compte l'authentification et voir si c'est 37o ou 31o envoyés ||||||| avec notif : 32o
    % max : 229 si pas d'options
    % Initialize fragments as a cell array
    fragments = {};
    
    if strcmp(packet_mode, 'Legacy')
        % Fragmentation for Legacy mode
        legacy_length = legacy_length_max - 10 * 8; % 31 octets = 248 bits utiles, -2octets -4octets de length et 4 octets pour adstructure et SIG
        if strcmp(discoverable_flag, "Y") == 1
            legacy_length = legacy_length - 3 * 8; % 3 octets si 02 01 06 au début
        end

        if strcmp(notif, "Y") == 1
            legacy_length = legacy_length - 3 * 8; % 4 octets si notif
        end

        if strcmp(name_flag, "Y") == 1
            name_length = length(name);
            legacy_length = legacy_length - (name_length+2) * 8; % Dépend de la taille du nom avec 2 octets au début
        end

        if legacy_length < 8
            error('The specified name is too large for a Legacy packet')
        end
        for i = 1:legacy_length:total_length
            % Extract a fragment of size legacy_length (or less for the last fragment)
            fragment = bitstream(i:min(i+legacy_length-1, total_length));
            
            % Add the fragment to the list
            fragments{end+1} = fragment;
        end
        
    elseif strcmp(packet_mode, 'Extended')
        % Fragmentation for Extended mode
        if strcmp(send_strategy, 'primary')
            % Stratégie primaire : tous les fragments sur le canal primaire

            extended_length = length_ext_frag_max * 8 - 4 * 8; % - 4 octets pour l'ADStructure (FF)

            if strcmp(discoverable_flag, 'Y') == 1
                extended_length = extended_length - 3 * 8; % - 4 octets pour l'ADStructure et - 3 octets pour le 02 01 06
            end
            if strcmp(name_flag, 'Y') == 1
                name_length = length(name)/2;
                extended_length = extended_length - (name_length+2) * 8; % Dépend de la taille du nom avec 2 octets au début
            end

            for i = 1:extended_length:total_length
                fragment = bitstream(i:min(i+extended_length-1, total_length));
                fragments{end+1} = fragment;
            end
                
            elseif strcmp(send_strategy, 'primary/secondary')
                % Stratégie primaire/secondaire : premier fragment sur le canal primaire,
                % les suivants sur les canaux secondaires
                extended_length = extended_length_max - 2 * 8; % À MODIFIER

                for i = 1:extended_length:total_length
                    fragment = bitstream(i:min(i+extended_length-1, total_length));
                    fragments{end+1} = fragment;
                end
                
            elseif strcmp(send_strategy, 'chained')
                % Stratégie tertiaire : fragments répartis sur plusieurs canaux
                % (implémentation spécifique à définir)
                error('Stratégie tertiaire non implémentée.');
            else
                error('Stratégie non reconnue.');
        end
    end
end
