function calculate_compression_ratio(original_file, compressed_file)
    original_info = dir(original_file);
    compressed_info = dir(compressed_file);
    original_size = original_info.bytes;
    compressed_size = compressed_info.bytes;
    ratio = original_size / compressed_size;
    fprintf('\nTaille originale : %d octets\n', original_size);
    fprintf('Taille compressée : %d octets\n', compressed_size);
    fprintf('Rapport de compression : %.2fx\n', ratio);
end