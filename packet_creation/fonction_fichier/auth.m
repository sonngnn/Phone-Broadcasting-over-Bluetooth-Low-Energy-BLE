function bitstream_auth = auth(bitstream)
    % Adds an authentification part at the beggining of the bitstrea

    % While no authentification function : just add 64 bytes (only 0 ?)
    
    authSuffix = zeros(1, 512); 
    
    % Add this prefix to the bitstream
    bitstream_auth = [bitstream, authSuffix];
end