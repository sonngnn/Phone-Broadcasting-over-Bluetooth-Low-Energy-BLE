function choice = ask_user(field)
    % Field : field that the user is asked to choose between several
    % options
    % Return : the option that the user has chosen

    % 6 possibilities of field to fill in

    if strcmp(field,"packet_mode") == 1
        % Choose between Legacy and Extended
        options = {'Legacy', 'Extended'}; % Define available options
        choice = ''; % Initialize the choice variable
        
        while ~ismember(choice, options)
            fprintf('Please choose an option from: %s or %s\n', options{1}, options{2});
            choice = input('Your choice: ', 's'); % Ask for user input
            
            if ~ismember(choice, options)
                fprintf('Invalid input. Please enter one of the available options.\n');
            end
        end
        
    fprintf('You have selected: %s\n', choice);

    elseif strcmp(field,"ble_mode") == 1
        % Choose between 1M and 125k
        options = {'1M', '125k'}; % Define available options
        choice = ''; % Initialize the choice variable
        
        while ~ismember(choice, options)
            fprintf('Please choose an option from: %s or %s\n', options{1}, options{2});
            choice = input('Your choice: ', 's'); % Ask for user input
            
            if ~ismember(choice, options)
                fprintf('Invalid input. Please enter one of the available options.\n');
            end
        end
        
    fprintf('You have selected: %s\n', choice);

    elseif strcmp(field,"strategy") == 1
        % Choose between primary, primary/secondary, chained
        options = {'primary', 'primary/secondary', 'chained'}; % Define available options
        choice = ''; % Initialize the choice variable
        
        while ~ismember(choice, options)
            fprintf('Please choose an option from: %s, %s or %s\n', options{1}, options{2}, options{3});
            choice = input('Your choice: ', 's'); % Ask for user input
            
            if ~ismember(choice, options)
                fprintf('Invalid input. Please enter one of the available options.\n');
            end
        end
        
        fprintf('You have selected: %s\n', choice);
        
    elseif strcmp(field,"address") == 1
        validInput = false; % Variable to check input validity
    
        while ~validInput
            macStr = input('Enter a 12-character AdvA: ', 's'); % Get user input
            
            if length(macStr) == 12 && all(isstrprop(macStr, 'xdigit')) % Check length and hex digits
                validInput = true;
            else
                fprintf('Invalid input. Please enter exactly 12 hexadecimal characters.\n');
            end
        end
        
        % Convert the hex string to a numerical array of 6 bytes
        hexBytes = reshape(macStr, 2, 6)'; % Split into 6 pairs of hex digits
        decimalBytes = uint8(hex2dec(hexBytes)); % Convert to decimal (uint8)
    
        % Convert each byte to an 8-bit binary vector (with MSB on the right)
        binaryMatrix = my_de2bi(decimalBytes, 8, 'right-msb');
        
        % Flatten the matrix into a single row vector
        binaryAddress = binaryMatrix';
        choice = binaryAddress(:)'; % Convert to row vector
        
        fprintf('ADVA (48-bit vector with MSB on the right):\n');
        disp(num2str(choice)); % Convert logical array to string for display

    elseif strcmp(field,"multiple") == 1

        validInput = false; % Variable to check input validity
    
        while ~validInput
            choice = input('Enter how many times a packet will be repeated (1 : not repeated): '); % Get user input
            
            if isnumeric(choice) && isscalar(choice) && choice >= 1 && mod(choice, 1) == 0
                validInput = true; % Valid input
            else
                fprintf('Invalid input. Please enter a whole number (integer) greater than or equal to 1.\n');
            end
        end
        
        fprintf('You entered: %d\n', choice);

    elseif strcmp(field,"filename") == 1
        % List of valid extensions
        validExtensions = {'.mp4', '.avi', '.mkv', '.mov', ...  % Video
                           '.jpg', '.jpeg', '.png', '.gif', '.bmp', ... % Image
                           '.mp3', '.wav', '.aac', '.flac', '.ogg', '.amr', '.m4a' ... % Audio
                           '.txt', '.csv', '.json', '.xml'}; % Text
                       
        validInput = false; % Variable to check input validity
        
        while ~validInput
            choice = input('Enter a filename (with extension): ', 's'); % Get user input
            
            [~, ~, ext] = fileparts(choice); % Extract extension
            
            if ~isempty(ext) && ismember(lower(ext), validExtensions)
                validInput = true; % Valid filename
            else
                fprintf('Invalid filename. Please enter a valid file with one of these extensions:\n');
                fprintf('%s\n', strjoin(validExtensions, ', ')); % Display allowed extensions
            end
        end
        
        fprintf('You entered a valid filename: %s\n', choice);

    elseif strcmp(field,"length") == 1
    
        validInput = false; % Variable to check input validity

        while ~validInput
            choice = input('Enter the maximum length of AdvData (max : 245): '); % Get user input
            
            if isnumeric(choice) && isscalar(choice) && choice <= 254  
                validInput = true; % Valid input
            else
                fprintf('Invalid input. Please enter a whole number (integer) lesser than or equal to 245.\n');
            end
        end
        
        fprintf('You entered: %d\n', choice);

    elseif strcmp(field, "discoverable") == 1

        validInput = false; % Variable to check input validity
    
        while ~validInput
            choice = input('Is the first ADStructure 02 01 06 ? (Y/N): ', 's'); % Get user input as string
            
            if strcmpi(choice, 'Y') || strcmpi(choice, 'N')
                validInput = true; % Valid input
            else
                fprintf('Invalid input. Please enter Y or N.\n');
            end
        end
    
        fprintf('You entered: %s\n', choice);
    
    
    elseif strcmp(field, "name_flag") == 1

        validInput = false; % Variable to check input validity
    
        while ~validInput
            choice = input('Include the name structure ? (Y/N): ', 's'); % Get user input as string
            
            if strcmpi(choice, 'Y') || strcmpi(choice, 'N')
                validInput = true; % Valid input
            else
                fprintf('Invalid input. Please enter Y or N.\n');
            end
        end
    
        fprintf('You entered: %s\n', choice);

    elseif strcmp(field, "name") == 1

        validInput = false; % Variable to check input validity

        while ~validInput
            nameInput = input('Enter a name: ', 's'); % Get user input as string
            
            if ~isempty(nameInput)
                validInput = true; % Valid input
            else
                fprintf('Invalid input. Please enter a non-empty name.\n');
            end
        end
        
        % Convert each character to hexadecimal and store in a cell array
        hexName = cell(1, length(nameInput));
        for i = 1:length(nameInput)
            hexName{i} = dec2hex(nameInput(i));
        end
        
        disp('Hexadecimal representation of the name:');
        disp(hexName);
        choice = hexName;

    elseif strcmp(field, "unique_binary_file") == 1

        validInput = false; % Variable to check input validity
    
        while ~validInput
            choice = input('Put all the binary stream in one file ? (Y/N): ', 's'); % Get user input as string
            
            if strcmpi(choice, 'Y') || strcmpi(choice, 'N')
                validInput = true; % Valid input
            else
                fprintf('Invalid input. Please enter Y or N.\n');
            end
        end
    
        fprintf('You entered: %s\n', choice);

    elseif strcmp(field,"method_image") == 1

        validInput = false; % Variable to check input validity
    
        while ~validInput
            choice = input('1: JPEG, 2: bitstream/channel, 3: other : '); % Get user input
            
            if isnumeric(choice) && isscalar(choice) && (choice == 1 || choice == 2 || choice == 3)
                validInput = true; % Valid input
            else
                fprintf('Invalid input. Please enter 1, 2 or 3.\n');
            end
        end
        
        fprintf('You entered: %d\n', choice);

    elseif strcmp(field, "mobile") == 1

        validInput = false; % Variable to check input validity
    
        while ~validInput
            choice = input('Reception with mobile phone ? (Y/N): ', 's'); % Get user input as string
            
            if strcmpi(choice, 'Y') || strcmpi(choice, 'N')
                validInput = true; % Valid input
            else
                fprintf('Invalid input. Please enter Y or N.\n');
            end
        end
    
        fprintf('You entered: %s\n', choice);

    elseif strcmp(field, "SIG") == 1
        validInput = false; % Variable to check input validity
    
        while ~validInput
            sigStr = input('Enter a 4-character SIG: ', 's'); % Get user input
            
            if length(sigStr) == 4 && all(isstrprop(sigStr, 'xdigit')) % Check length and hex digits
                validInput = true;
            else
                fprintf('Invalid input. Please enter exactly 4 hexadecimal characters.\n');
            end
        end
    
        % Store the SIG as a vector of characters
        hex_str = hex2dec(sigStr);

        choice = hex_str;
        
        fprintf('SIG Vector (4 hexadecimal symbols):\n');
        disp(choice);

    elseif strcmp(field, "entrelacage") == 1

        validInput = false; % Variable to check input validity
    
        while ~validInput
            choice = input('Entrelacer les paquets répétés ? (Y/N): ', 's'); % Get user input as string
            
            if strcmpi(choice, 'Y') || strcmpi(choice, 'N')
                validInput = true; % Valid input
            else
                fprintf('Invalid input. Please enter Y or N.\n');
            end
        end
    
        fprintf('You entered: %s\n', choice);

    elseif strcmp(field, "notif") == 1

        validInput = false; % Variable to check input validity
    
        while ~validInput
            choice = input('Send a notification with mobile phone ? (Y/N): ', 's'); % Get user input as string
            
            if strcmpi(choice, 'Y') || strcmpi(choice, 'N')
                validInput = true; % Valid input
            else
                fprintf('Invalid input. Please enter Y or N.\n');
            end
        end
    
        fprintf('You entered: %s\n', choice);

    end
end


