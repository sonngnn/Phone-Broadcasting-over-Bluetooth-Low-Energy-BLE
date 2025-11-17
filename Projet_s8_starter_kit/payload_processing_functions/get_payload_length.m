function length_payload_bits = get_payload_length(length_payload)
length_payload_bits = int2bit(length_payload,8)';
length_payload_bits = fliplr(length_payload_bits);
length_payload_bits = (swap_rows_two_by_two(length_payload_bits));
length_payload_bits = reshape(length_payload_bits',[],1);
end
