function length_payload_bits = get_ext_header_length(length_payload)
length_payload_bits = int2bit(length_payload,6)';
length_payload_bits = fliplr(length_payload_bits);
length_payload_bits = reshape(length_payload_bits',[],1);
end
