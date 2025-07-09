function nextChannel = updateChannelConditions(currentChannel, params)
    fluctuation = 0.05 * randn(size(currentChannel));
    nextChannel = currentChannel + fluctuation;
    nextChannel = max(0, min(1, nextChannel));  % Clamp between 0 and 1
end