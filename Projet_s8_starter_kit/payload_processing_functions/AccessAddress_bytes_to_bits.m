function Access_address_bits = AccessAddress_bytes_to_bits(hex_access_address)
% Transforme la séquence d'access address en binaire en Hexa
Access_address_bits = rot90(hex_cell_to_binary_matrix(hex_access_address),2);
Access_address_bits = reshape(Access_address_bits',[],1);
end
