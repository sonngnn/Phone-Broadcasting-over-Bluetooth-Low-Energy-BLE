function binaryStream = file_to_bitstream_text(filename)
    % Open the text file in read mode
    fileID = fopen(filename, 'r');
    
    % Check if the file was opened successfully
    if fileID == -1
        error('The specified file could not be opened.');
    end
    
    % Read the content of the file
    fileContent = fread(fileID, '*char')'; % Read the entire file content as a character array
    fclose(fileID); % Close the file

    % Convert each character to binary (8 bits per character)
    binChars = dec2bin(fileContent, 8);         % Matrix of binary strings (1 row per char)
    binCharsLE = binChars(:, end:-1:1);         % Inversion bitwise → little-endian per char
    binaryStream = binCharsLE';                 % Transpose to stack bits vertically
    binaryStream = binaryStream(:) - '0';       % Convert characters to integers 0/1
    binaryStream = binaryStream';               % Return as a row vector
end
