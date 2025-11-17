function preamble = preambleGenerator(phyMode)
%
%   preamble = preambleGenerator(PHYMODE) generates preamble,
%   preamble, based on PHYMODE.
%
%   PREAMBLE is binary column vector of type double. For LE1M and LE2M,
%   PREAMBLE is a sequence of alternate 0's and 1's of length 8 and 16
%   respectively. Whereas, for modes LE500K and LE125K, PREAMBLE is a
%   80-bit sequence obtained by repeating [0 0 1 1 1 1 0 0] 10 times.
%
%   PHYMODE is a character vector or a string, must be one of the
%   following: 'LE1M','LE2M','LE500K','LE125K'.


% Generate preamble sequence for given mode
if(strcmp(phyMode,'LE1M'))
    % 8-bit alternate 0's and 1's
    preamble = double([0 1 0 1 0 1 0 1]');
elseif(strcmp(phyMode,'LE2M'))
    % 16-bit alternate 0's and 1's
    preamble = double([0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1]');
else% LE125K or LE500K
    % 80-bit sequence with repeated pattern of [0 0 1 1 1 1 0 0]
    preamble = repmat([0 0 1 1 1 1 0 0]',10,1);
end
