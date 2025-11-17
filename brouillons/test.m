% Signal voix/vidéo compressé et découpé en séquence de x octets

% Création préambule et AA

% PDU (comment remplir tous les champs etc...)
% -> avoir addresse MAC

% CRC de PDU

% Whitening de PDU + CRC

% Concaténation préambule + AA + PDU + CRC
% Modulation GMSK

% Pb liés au frequency hopping, recouvrement avec MWS...

message = randi([0 1],10000,1);
phyMode = "LE125K";
sps = 4;
symbolRate = 1e6;
channIdx = 36;
crcGen = comm.CRCGenerator('z^24+z^10+z^9+z^6+z^4+z^3+z+1', ...
    'InitialConditions',int2bit(hex2dec('555551'),24), ...
    'DirectMethod',true);

crcDec = comm.CRCDetector('z^24+z^10+z^9+z^6+z^4+z^3+z+1', ...
    'InitialConditions',int2bit(hex2dec('555551'),24), ...
    'DirectMethod',true);

msgCRC = crcGen(message);

waveform = bleWaveformGenerator(msgCRC,"Mode",phyMode,"SamplesPerSymbol",sps,"ModulationIndex",0.5,"PulseLength",3,'ChannelIndex',channIdx);

snr = 30;                          % In dB
rxWaveform = awgn(waveform,snr);

[rxBits,accessAddr] = bleIdealReceiver(rxWaveform,"Mode",phyMode,"SamplesPerSymbol",sps,"ModulationIndex",0.5,"PulseLength",3,'ChannelIndex',channIdx);

[outputBits,err] = crcDec(double(rxBits));

numErr = biterr(message,outputBits);