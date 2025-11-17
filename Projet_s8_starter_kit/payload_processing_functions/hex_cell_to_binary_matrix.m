function binary_matrix = hex_cell_to_binary_matrix(hex_cell)
    % This function converts a cell array of hexadecimal strings into a binary matrix.
    
    % Get the number of elements in the cell array
    num_elements = length(hex_cell);
    
    % Initialize an empty binary matrix
    binary_matrix = [];
    
    % Loop over each cell
    for i = 1:num_elements
        % Get the hexadecimal sequence from the cell
        hex_sequence = hex_cell{i};
        
        % Initialize an empty row vector for the current hex sequence
        binary_row = [];
        
        % Loop over each hexadecimal character in the sequence
        for j = 1:length(hex_sequence)
            % Convert each hex character to a 4-bit binary string
            binary_string = dec2bin(hex2dec(hex_sequence(j)), 4);
            
            % Convert the binary string to a vector of integers and append it
            binary_row = [binary_row, str2num(binary_string(:))'];
        end
        
        % Append the current binary row to the binary matrix
        binary_matrix = [binary_matrix; binary_row];  % Append as new row
    end
end
