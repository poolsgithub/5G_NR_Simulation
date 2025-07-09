function UEs = generateTraffic(UEs, params, currentTTI)
    for ue = 1:params.numUEs
        if rand < 0.3 % 30% chance of packet arrival
            packetSize = randi([100, 500]); % in bits
            UEs(ue).bsr = UEs(ue).bsr + packetSize;
        end
    end
end
