function filename = saveSignalToFile(tx_waveform_doppler, ble_mode, packet_mode)
    env_I_synthetic = real(tx_waveform_doppler).';
    env_Q_synthetic = imag(tx_waveform_doppler).';
    mat_env_formatIQ_synthetic = [env_I_synthetic;env_Q_synthetic];
    env_formatIQ_synthetic = 64 * reshape(mat_env_formatIQ_synthetic,1,[]); % 128 for full-scale bits as HackRF ADCs are 8-bit

    filename = sprintf('B%s_%s.bin', ble_mode, packet_mode); % Save file name

    file = fopen(filename, 'w+');
    fwrite(file, env_formatIQ_synthetic, 'int8');
    fclose(file);
end