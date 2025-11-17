function fileType = get_file_type(filename)
    % Define valid extensions and their corresponding unique numbers
    fileCategories = {...
        {'.mp4', '.avi', '.mkv', '.mov'}, 4; ...  % Video -> 4
        {'.jpg', '.jpeg', '.png', '.gif', '.bmp'}, 3; ... % Image -> 3
        {'.mp3', '.wav', '.aac', '.flac', '.ogg', '.amr', '.m4a'}, 2; ... % Audio -> 2
        {'.txt', '.csv', '.json', '.xml'}, 1 ... % Text -> 1
    };

    % Extract extension from filename
    [~, ~, ext] = fileparts(filename);

    % Convert extension to lowercase for case-insensitive matching
    ext = lower(ext);
    
    % Default type if no match found
    fileType = -1;

    % Check which category the extension belongs to
    for i = 1:size(fileCategories, 1)
        if ismember(ext, fileCategories{i, 1})
            fileType = fileCategories{i, 2};
            return; % Stop checking once found
        end
    end
    
    % Display an error if no valid type is found
    if fileType == -1
        error('Invalid file type. Please provide a valid filename with a supported extension.');
    end
end
