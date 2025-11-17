function filename = saveSignalToFile(packets_modulated, ble_mode, packet_mode, unique_binary_file, interval_time,data_rate,sps, multiple_send,mobile,entrelacage)
    delete('./binary_file/*.bin'); 
    
    %% Si Réception via antenne
    if strcmp(mobile, "N") == 1
        if strcmp(unique_binary_file,"Y") == 1
            if strcmp(entrelacage, "Y") == 1
                wait_time = interval_time * sps * data_rate;
                wait_vector = zeros(1,wait_time);
                final_env_formatIQ_synthetic = [];
                for nb_sent = 1:multiple_send
                    for idx = 1:length(packets_modulated)
                        tx_waveform_doppler = packets_modulated{idx}(nb_sent,:).';
                        env_I_synthetic = real(tx_waveform_doppler).';
                        env_Q_synthetic = imag(tx_waveform_doppler).';
                        mat_env_formatIQ_synthetic = [env_I_synthetic;env_Q_synthetic];
                        env_formatIQ_synthetic = 64 * reshape(mat_env_formatIQ_synthetic,1,[]); % 128 for full-scale bits as HackRF ADCs are 8-bit
                        final_env_formatIQ_synthetic = [final_env_formatIQ_synthetic env_formatIQ_synthetic wait_vector];
                    end
                end
            else
                wait_time = interval_time * sps * data_rate;
                wait_vector = zeros(1,wait_time);
                final_env_formatIQ_synthetic = [];
                for idx = 1:length(packets_modulated)
                    for nb_sent = 1:multiple_send
                    tx_waveform_doppler = packets_modulated{idx}(nb_sent,:).';
                    env_I_synthetic = real(tx_waveform_doppler).';
                    env_Q_synthetic = imag(tx_waveform_doppler).';
                    mat_env_formatIQ_synthetic = [env_I_synthetic;env_Q_synthetic];
                    env_formatIQ_synthetic = 64 * reshape(mat_env_formatIQ_synthetic,1,[]); % 128 for full-scale bits as HackRF ADCs are 8-bit
                    final_env_formatIQ_synthetic = [final_env_formatIQ_synthetic env_formatIQ_synthetic wait_vector];
                    end
                end
            end
        
                filename = sprintf('./binary_file/BLE%s_%s_unique.bin', ble_mode, packet_mode); % Save file name
                
                file = fopen(filename, 'w+');
                fwrite(file, final_env_formatIQ_synthetic, 'int8');
                fclose(file);
    
        else
            for idx = 1:length(packets_modulated)
                for nb_sent = 1:multiple_send
                tx_waveform_doppler = packets_modulated{idx}(nb_sent,:).';
                env_I_synthetic = real(tx_waveform_doppler).';
                env_Q_synthetic = imag(tx_waveform_doppler).';
                mat_env_formatIQ_synthetic = [env_I_synthetic;env_Q_synthetic];
                env_formatIQ_synthetic = 64 * reshape(mat_env_formatIQ_synthetic,1,[]); % 128 for full-scale bits as HackRF ADCs are 8-bit
            
                filename = sprintf('./binary_file/BLE%s_%s_n%i_%i.bin', ble_mode, packet_mode, idx, nb_sent); % Save file name
            
                file = fopen(filename, 'w+');
                fwrite(file, env_formatIQ_synthetic, 'int8');
                fclose(file);
    
                end
            end
        end

    %% Si réception via mobile
    else
        % Si dans un seul fichier binaire
        if strcmp(unique_binary_file,"Y") == 1
            % Entrlaçace : P1 P2 P3 P1 P2 P3 P1 P2 P3 ...
            if strcmp(entrelacage, "Y") == 1
                wait_time = interval_time * sps * data_rate *2;
                wait_vector = zeros(1,wait_time);
                wait_size = length(wait_vector);
                final_env_formatIQ_synthetic = zeros(1,(length(packets_modulated{1}(1,:))*2+ wait_size)*multiple_send*(length(packets_modulated)-1)+ (length(packets_modulated{end}(1,:))*2 + wait_size)*multiple_send);
                ptr = 1;
                for nb_sent = 1:multiple_send
                    for idx = 1:length(packets_modulated)
                        tx_waveform_doppler = packets_modulated{idx}(nb_sent,:).';
                        env_I_synthetic = real(tx_waveform_doppler).';
                        env_Q_synthetic = imag(tx_waveform_doppler).';
                        mat_env_formatIQ_synthetic = [env_I_synthetic;env_Q_synthetic];
                        env_formatIQ_synthetic = 64 * reshape(mat_env_formatIQ_synthetic,1,[]); % 128 for full-scale bits as HackRF ADCs are 8-bit
                        
                        len_iq = length(env_formatIQ_synthetic);
                        final_env_formatIQ_synthetic(ptr : ptr + len_iq - 1) = env_formatIQ_synthetic;
                        ptr = ptr + len_iq;
            
                        final_env_formatIQ_synthetic(ptr : ptr + wait_size - 1) = wait_vector;
                        ptr = ptr + wait_size;
                    end
                end
                filename = sprintf('./binary_file/BLE%s_%s_frame_1.bin', ble_mode, packet_mode); % Save file name
                
                file = fopen(filename, 'w+');
                fwrite(file, final_env_formatIQ_synthetic, 'int8');
                fclose(file);
            
            % Pas entrelaçage : P1 P1 P1 P2 P2 P2 P3 P3 P3
            else
                wait_time = interval_time * sps * data_rate;
                wait_vector = zeros(1,wait_time);
                final_env_formatIQ_synthetic = [];
                for idx = 1:length(packets_modulated)
                    for nb_sent = 1:multiple_send
                    tx_waveform_doppler = packets_modulated{idx}(nb_sent,:).';
                    env_I_synthetic = real(tx_waveform_doppler).';
                    env_Q_synthetic = imag(tx_waveform_doppler).';
                    mat_env_formatIQ_synthetic = [env_I_synthetic;env_Q_synthetic];
                    env_formatIQ_synthetic = 64 * reshape(mat_env_formatIQ_synthetic,1,[]); % 128 for full-scale bits as HackRF ADCs are 8-bit
                    final_env_formatIQ_synthetic = [final_env_formatIQ_synthetic env_formatIQ_synthetic wait_vector];
                    end
                end
        
                filename = sprintf('./binary_file/BLE%s_%s_frame_1.bin', ble_mode, packet_mode); % Save file name
                
                file = fopen(filename, 'w+');
                fwrite(file, final_env_formatIQ_synthetic, 'int8');
                fclose(file);
            end
       
        % Si dans plusieurs fichiers binaires
        else
            for idx = 1:length(packets_modulated)
                for nb_sent = 1:multiple_send
                tx_waveform_doppler = packets_modulated{idx}(nb_sent,:).';
                env_I_synthetic = real(tx_waveform_doppler).';
                env_Q_synthetic = imag(tx_waveform_doppler).';
                mat_env_formatIQ_synthetic = [env_I_synthetic;env_Q_synthetic];
                env_formatIQ_synthetic = 64 * reshape(mat_env_formatIQ_synthetic,1,[]); % 128 for full-scale bits as HackRF ADCs are 8-bit
            
                filename = sprintf('./binary_file/BLE%s_%s_frame_%i.bin', ble_mode, packet_mode, idx); % Save file name
            
                file = fopen(filename, 'w+');
                fwrite(file, env_formatIQ_synthetic, 'int8');
                fclose(file);
    
                end
            end
        end
    end
end