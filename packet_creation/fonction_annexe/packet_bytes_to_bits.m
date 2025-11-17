function packet_bits = packet_bytes_to_bits(hex_packet)
packet_bits = (fliplr(hex_cell_to_binary_matrix(hex_packet)));
packet_bits = (swap_rows_two_by_two(packet_bits));
packet_bits = reshape(packet_bits',[],1)';
end
