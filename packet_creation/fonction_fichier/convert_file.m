function [bitstream, data_type] = convert_file(filename)
    % INPUT : filename of the file that will be converted into a bitstream
    % OUTPUT : the bitstream of the file and the type of it
    % (text/audio/image/video)

    % To choose the correct algorithm we need to know the type of data
    file_type = get_file_type(filename);

    if file_type == 1
        % if text
        bitstream = file_to_bitstream_text(filename);
    elseif file_type == 2
        % if audio
        bitstream = file_to_bitstream_audio(filename);
        bitstream = bitstream.';
    elseif file_type == 3
        % if image
        % if options are needed : call function ask_user
        %method = ask_user("method_image");
        method = 3;
        bitstream = file_to_bitstream_image(filename, method);
        bitstream = double(bitstream).';
    else 
        % if video
        bitstream = file_to_bitstream_video(filename);
    end
    
    data_type = my_de2bi(file_type-1, 2, 'right-msb');
end


