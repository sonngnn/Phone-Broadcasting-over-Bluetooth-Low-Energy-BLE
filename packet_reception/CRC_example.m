

poly= 'X^24 + X^23 + X^22 + X^21 + X^20 + X^19 + X^18 + X^17 + X^16 + X^15 + X^14 + X^13 + X^12 + X^10 + X^3 + 1';


% generation d'une trame aléatoire 
N=1000;
trame_env=randi([0 1],N);
% encodage CRC -> conversion de logical à vecteur int -> transposition
bitsTx =  double(encode_frame(trame_env,poly))';

% **** Modulation
% **** Canal
% **** Démodulation

bitsRx=bitsTx;
% CRC
[trame_rec,err]=decode_frame(logical(bitsRx)',poly); % conversion double en logical -> décodage de la trame
TEB = norm(double(err))/length(bitsRx);
fprintf("TEB: %2f\n",TEB)
%% Functions
function [decoded_frame, err]=decode_frame(frame,generator_poly)
    % Décode la trame frame à l'aide du polynôme générateur poly
    % Tâche 3
    crc_configurator=crcConfig(Polynomial=generator_poly,ChecksumsPerFrame=1);
    [decoded_frame, err]=crcDetect(frame,crc_configurator);
end

function encoded_frame=encode_frame(frame,generator_poly)
    % Encode la trame frame à l'aide du polynôme générateur poly
    % Tâche 3
    crc_configurator=crcConfig(Polynomial=generator_poly,ChecksumsPerFrame=1);
    encoded_frame=crcGenerate(frame,crc_configurator);
end
