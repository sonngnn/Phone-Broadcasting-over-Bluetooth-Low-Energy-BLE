function swapped_matrix = swap_rows_two_by_two(matrix)
    % Obtenir le nombre de lignes de la matrice
    [num_rows, num_cols] = size(matrix);
    
    % Initialiser la matrice avec les mêmes dimensions
    swapped_matrix = matrix;
    
    % Boucler sur les lignes deux par deux
    for i = 1:2:num_rows-1
        % Utiliser une variable temporaire pour stocker la ligne i
        temp_row = swapped_matrix(i, :);
        
        % Échanger les lignes i et i+1
        swapped_matrix(i, :) = swapped_matrix(i+1, :);
        swapped_matrix(i+1, :) = temp_row;
    end
end
