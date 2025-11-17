function cell_preallocated = preallocating_cell(nb_different_packet, multiple_send, max_length, last_length)
    % Initialize an empty cell array
    cell_preallocated = cell(1, nb_different_packet);  

    % Fill the first (nb_different_packet - 1) cells with zero matrices
    for i = 1:(nb_different_packet - 1)
        cell_preallocated{i} = zeros(multiple_send, max_length);
    end
    
    % Fill the last cell with a zero matrix of a different size
    cell_preallocated{nb_different_packet} = zeros(multiple_send, last_length);
end