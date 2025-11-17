function hex_cell = binary_matrix_to_hex_cell(binary_matrix)
    % This function converts a binary matrix back into a cell array of hexadecimal strings.

    % Flip the binary matrix back if `fliplr` was used
    binary_matrix = fliplr(binary_matrix);

    % Initialize an empty cell array
    hex_cell = cell(1, size(binary_matrix, 1));

    % Loop over each row in the binary matrix
    for i = 1:size(binary_matrix, 1)
        % Initialize an empty string for the current hex sequence
        hex_sequence = '';

        % Process each 4-bit chunk in the row
        for j = 1:4:length(binary_matrix(i, :))
            % Extract the 4-bit binary segment
            binary_segment = binary_matrix(i, j:j+3);

            % Convert the binary segment to decimal, then to hexadecimal
            hex_char = dec2hex(bin2dec(num2str(binary_segment)));

            % Append the hexadecimal character to the sequence
            hex_sequence = [hex_sequence, hex_char];
        end

        % Store the current hex sequence in the cell array
        hex_cell{i} = hex_sequence;
    end
end
