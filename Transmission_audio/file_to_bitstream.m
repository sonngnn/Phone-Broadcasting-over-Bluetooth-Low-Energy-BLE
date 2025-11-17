% Conversion d'un fichier en flux de bits
function bitstream = file_to_bitstream(filename)
    % Ouvre le fichier en mode binaire
    fid = fopen(filename, 'rb');
    if fid == -1
        error('Impossible d''ouvrir le fichier: %s', filename);
    end
    % Lecture du contenu du fichier sous forme d'octets (uint8)
    data = fread(fid, '*uint8');
    fclose(fid);
    
    n = numel(data);
    % Initialisation d'une matrice pour stocker les bits (chaque ligne = 1 octet)
    bits = zeros(n, 8);
    for i = 1:8
        % Extraction des bits du plus significatif au moins significatif
        bits(:, i) = bitget(data, 9 - i);
    end
    % Transformation de la matrice en vecteur ligne de bits
    bitstream = reshape(bits.', 1, []);
end

