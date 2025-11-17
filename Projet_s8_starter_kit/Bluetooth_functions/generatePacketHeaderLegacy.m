function data_to_send = generatePacketHeaderLegacy(payload, new_header)
        if length(payload)/8 > 37
            error('The specified payload is too large for a Legacy packet (> 37)')
        end
        data_to_send = [new_header; payload]; 
end