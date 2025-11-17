% Reconstruction d'un fichier à partir d'un flux de bits
function bitstream_to_file(bitstream, filename)
    % Vérifie que la longueur du flux est un multiple de 8
    if mod(length(bitstream), 8) ~= 0
        error('La longueur du flux de bits n''est pas un multiple de 8.');
    end
    n = length(bitstream) / 8;
    % Reshape du vecteur en matrice où chaque ligne représente un octet
    bits_matrix = reshape(bitstream, 8, n).';
    
    % Conversion de chaque ligne (octet) en une valeur uint8
    data = zeros(n, 1, 'uint8');
    for i = 1:n
        byte = 0;
        for bit = 1:8
            byte = byte + bits_matrix(i, bit) * 2^(8 - bit);
        end
        data(i) = byte;
    end
    
    % Écriture du fichier reconstruit en mode binaire
    fid = fopen(filename, 'wb');
    if fid == -1
        error('Impossible d''ouvrir le fichier pour écriture : %s', filename);
    end
    fwrite(fid, data, 'uint8');
    fclose(fid);
end