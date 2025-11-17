function packet_coded = fec(packet,ble_mode)
    % Compute the FEC code if needed (ie ble_mode=125k) for the current packet

    if strcmp(ble_mode, "1M")
        % Uncoded
        packet_coded = packet;
    else
        % Coded 125k
        % Each bit, except the preamble (8 firsts bits), go through a convolutional code with 2 outputs and each
        % output is coded with a 4-bits-length code
        
        % Generator polynomial
        polynom0 = [1 1 1 1];
        polynom1 = [1 0 1 1];

        % Memory of the code start with only 0
        memory = [0 0 0];

        % Coding available
        code = [0 0 1 1; ... % When input = 0
                1 1 0 0]; % When output = 1

        % Pre-allocating
        packet_coded = zeros(1,length(packet)*8 + 2*8); % Preamble repeted 10 times

        for bits_number=1+8:length(packet)
            packet_part0 = mod(sum([packet(bits_number) memory].*polynom0),2);
            packet_part1 = mod(sum([packet(bits_number) memory].*polynom1),2);

            memory(2:3) = memory(1:2);
            memory(1) = packet(bits_number);
    
            packet_coded((bits_number+1)*8+1:(bits_number+2)*8) = [code(packet_part0 + 1,:) code(packet_part1 + 1,:)];

        end

        packet_coded(1:80) = repmat(packet(1:8),1,10); % Add the preamble repeated 10 times to the coded bits

    end
    