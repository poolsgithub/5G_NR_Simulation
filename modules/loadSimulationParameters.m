function params = loadSimulationParameters()
    params.simTime = 1000;
    params.numUEs = 5;
    params.bwpSize = 50;
    params.mcsTable = 1:15;
    params.schedulerType = 'roundRobin'; % Options: 'roundRobin', 'maxThroughput', 'proportionalFair'
    params.adaptiveMCS = true;
    params.numHARQProcesses = 4;
end
