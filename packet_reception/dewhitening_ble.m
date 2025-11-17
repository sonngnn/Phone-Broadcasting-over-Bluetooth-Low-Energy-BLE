function out_array = dewhitening_ble(bits, channel)
    % Applique le *dewhitening* BLE à une séquence de bits,
    % en utilisant le même LFSR que pour le whitening.
    %
    % Comme le whitening est basé sur un XOR avec une séquence pseudo-aléatoire,
    % il est réversible en le réappliquant (XOR est son propre inverse).
    %
    % Args:
    %   bits    : Tableau de bits à déwhitener.
    %   channel : Canal BLE utilisé (0 à 39).
    %
    % Returns:
    %   out_array : Séquence de bits déwhitened.

    % Polynôme x^7 + x^4 + 1
    polynomial = zeros(1, 8);
    exponents = [1, 5, 8];  % correspond à x^0, x^4, x^7
    polynomial(exponents) = 1;
    working_poly = polynomial(1:7);

    % Initialisation du LFSR
    ch_str = dec2bin(channel, 6);
    channel_array = zeros(1, 6);
    for i = 1:6
        channel_array(i) = str2double(ch_str(i));
    end
    state = [1, channel_array];

    % Déwhitening = re-whitening
    nBits = length(bits);
    out_array = zeros(1, nBits);
    for i = 1:nBits
        out_bit = state(end);
        dewhitened_bit = xor(bits(i), out_bit);
        out_array(i) = dewhitened_bit;

        % Mise à jour du LFSR
        state = [0, state(1:end-1)];
        xor_array = out_bit * working_poly;
        state = bitxor(state, xor_array);
    end
end
