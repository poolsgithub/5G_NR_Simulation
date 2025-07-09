function [gNB, UEs, channelMatrix] = initializeNetwork(params)
    gNB = struct(); % Simple placeholder
    
    for i = 1:params.numUEs
        UEs(i).bsr = 0;
        UEs(i).harqProcesses = cell(1, params.numHARQProcesses);
        UEs(i).averageThroughput = 1;
    end
    
    % Initialize simple channel matrix [UEs x Time]
    channelMatrix = rand(params.numUEs, params.simTime);
end
