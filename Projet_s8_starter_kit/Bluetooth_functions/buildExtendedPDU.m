function pduBits = buildExtendedPDU(headerBits, extendedHeaderBits, fieldsStruct, extHeaderFlags, payloadBits)
% buildExtendedPDU
% Concatène le header, l'extended header, l'extended header flags puis conditionnellement
% les champs advA, targetA, CTE, ADI, auxPtr, syncInfo, txPower, rfu,
% suivis de la payload.
%
%
% ENTREE :
%   headerBits         : vecteur de bits du header principal
%   extendedHeaderBits : vecteur de bits de l'extended header 
%   fieldsStruct       : structure contenant :
%                        - fieldsStruct.advA     (bits)
%                        - fieldsStruct.targetA  (bits)
%                        - fieldsStruct.cte      (bits)
%                        - fieldsStruct.ADI      (bits)
%                        - fieldsStruct.auxptr   (bits)
%                        - fieldsStruct.syncinfo (bits)
%                        - fieldsStruct.txPower  (bits)
%                        - fieldsStruct.rfu      (bits)
%   extHeaderFlags        : vecteur binaire, indiquant
%                        la présence (1) ou l'absence (0) de chacun
%                        de ces champs, dans l'ordre advA, targetA, 
%                        cte, ADI, auxptr, syncinfo, txPower, rfu.
%   payloadBits        : vecteur de bits pour la payload.
%
% SORTIE :
%   pduBits : le paquet final (vecteur de bits).
%
    % On commence la concaténation avec le header + extended header + flags
    pduBits = [headerBits; extendedHeaderBits; extHeaderFlags];

    % Index 1 => advA
    if extHeaderFlags(1) == 1
        pduBits = [pduBits; fieldsStruct.advA];
    end

    % Index 2 => targetA
    if extHeaderFlags(2) == 1
        pduBits = [pduBits; fieldsStruct.targetA];
    end

    % Index 3 => cte
    if extHeaderFlags(3) == 1
        pduBits = [pduBits; fieldsStruct.cte];
    end

    % Index 4 => ADI
    if extHeaderFlags(4) == 1
        pduBits = [pduBits; fieldsStruct.ADI];
    end

    % Index 5 => auxPtr
    if extHeaderFlags(5) == 1
        pduBits = [pduBits; fieldsStruct.auxptr];
    end

    % Index 6 => syncInfo
    if extHeaderFlags(6) == 1
        pduBits = [pduBits; fieldsStruct.syncinfo];
    end

    % Index 7 => txPower
    if extHeaderFlags(7) == 1
        pduBits = [pduBits; fieldsStruct.txPower];
    end

    % Index 8 => rfu
    if extHeaderFlags(8) == 1
        pduBits = [pduBits; fieldsStruct.rfu];
    end

    % Enfin, on ajoute la payload 
    pduBits = [pduBits; payloadBits];
end
