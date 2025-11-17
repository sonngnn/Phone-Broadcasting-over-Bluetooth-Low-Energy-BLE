function states = channelWhitening(nChannel)
    nEncode = 6;
    n = 2^7 - 1;
    initState = de2bi(nChannel, "right-msb", nEncode);
    initState = cat(2, [1], initState);
    current = initState;
    next = zeros(size(initState));
    states = zeros(n, length(initState));
    
    for i = 1:n
        states(i, :) = current;
        next(2:end) = current(1:end-1);
        next(1) = current(end);
        next(5) = mod(current(4) + current(end), 2);
        current = next;
    end
    
    assert(isequal(unique(states, "rows", "stable"), states));
end

% Generate states for different channels
nEncode = 6;
n = 2^7;
allStates = zeros(n - 1, nEncode + 1, 40);

for j = 0:39
    allStates(:, :, j + 1) = channelWhitening(j);
end