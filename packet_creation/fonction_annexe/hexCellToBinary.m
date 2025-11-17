function binaryStream = hexCellToBinary(hexCell)
    % Convert a cell array of single-character hexadecimal strings 
    % into a binary row vector with MSB on the right.

    % Convert each hex character to decimal
    decimalValues = cellfun(@hex2dec, hexCell); 

    % Convert decimal values to binary with MSB on the right
    binaryMatrix = my_de2bi(decimalValues, 4, 'left-msb'); % 4 bits per hex digit

    % Flatten to a row vector
    binaryStream = [];
    for i = 1:size(binaryMatrix, 1)
        binaryStream = [binaryStream, binaryMatrix(i, :)];
    end
    binaryStream = fliplr(binaryStream);
end
