function out_array = whitening_ble(bits, channel)
    % Applique le whitening BLE à une séquence de bits, en utilisant un LFSR.
    %
    % Args:
    %   bits    : Tableau (row ou column) de bits d'entrée (0 ou 1).
    %   channel : Index du canal BLE (0 à 39).
    %
    % Returns:
    %   out_array : Séquence de bits whitened (même taille que bits).
    %
    % Le polynôme de whitening est x^7 + x^4 + 1 (positions [0, 4, 7] en base 0).
    % Nous construisons d'abord un vecteur polynomial de taille 8 (indexé 1..8 en MATLAB).
    % Puis nous excluons le terme x^8, inutilisé (comme dans votre code Python).
    
    % -----------------------------
    % 1) Définition du polynôme (x^7 + x^4 + 1)
    % -----------------------------
    polynomial = zeros(1, 8);      % Tableau de 8 éléments
    exponents  = [1, 5, 8];        % x^0, x^4, x^7 en base 0 => indices +1 en MATLAB
    polynomial(exponents) = 1;     % Place des '1' aux positions voulues
    
    % working_poly correspond à polynomial[:-1] en Python
    working_poly = polynomial(1:7);  % On exclut le dernier terme (x^8)
    
    % -----------------------------
    % 2) Initialisation du LFSR
    % -----------------------------
    % La spécification BLE demande 6 bits de canal, plus un MSB = 1.
    % Conversion du canal en binaire sur 6 bits
    ch_str = dec2bin(channel, 6);  % ex. '000101'
    
    % Transformation en tableau [int,int,...]
    channel_array = zeros(1, 6);
    for i = 1:6
        channel_array(i) = str2double(ch_str(i));
    end
    
    % État initial : [1, channel_array], soit un vecteur de taille 7
    % En Python : state = np.array([1] + channel_array)
    state = [1, channel_array];
    
    % -----------------------------
    % 3) Boucle de whitening (LFSR)
    % -----------------------------
    nBits = length(bits);
    out_array = zeros(1, nBits);  % Pour stocker la séquence de sortie
    
    for i = 1:nBits
        % out_bit = state[-1] en Python => le dernier élément (LSB)
        out_bit = state(end);
        
        % whitened_bit = bit XOR out_bit
        whitened_bit = xor(bits(i), out_bit);
        out_array(i) = whitened_bit;
        
        % Décalage du registre LFSR vers la droite
        % state = np.insert(state[:-1], 0, 0) en Python
        % => on insère un 0 au début et on enlève le dernier élément
        state = [0, state(1:end-1)];
        
        % Application du feedback en fonction du polynôme
        % xor_array = out_bit * working_poly
        % => si out_bit=1, xor_array = working_poly; sinon = 0
        xor_array = out_bit * working_poly;
        
        % state = np.bitwise_xor(state, xor_array)
        state = bitxor(state, xor_array);
    end
    out_array = out_array.';
end
