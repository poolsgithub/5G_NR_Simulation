% ----------- main.m - Minimal 5G NR MAC Protocol Simulation -----------

clear; clc; close all;

% Add module path
addpath('./modules');

% Load simulation parameters
params = loadSimulationParameters();

% Ask user to override defaults (interactive)
params = getUserParameters(params);


% Initialize network
[gNB, UEs, channelMatrix] = initializeNetwork(params);

% Init HARQ feedback
harqFeedback = repmat(struct('ACK', false, 'valid', false, 'pending', false(1, params.numHARQProcesses)), params.numUEs, 1);

% Data collection
dataCollector.ack = zeros(params.simTime, params.numUEs);
dataCollector.nack = zeros(params.simTime, params.numUEs);
dataCollector.retx = zeros(params.simTime, params.numUEs);

fprintf('\nStarting simulation...\n\n');

for t = 1:params.simTime
    if mod(t, 100) == 0
        fprintf('Progress: %3.0f%% complete\n', t / params.simTime * 100);
    end

    UEs = generateTraffic(UEs, params, t);
    [allocations, selectedMCS] = runScheduler(UEs, harqFeedback, channelMatrix(:, t), params);
    [UEs, txResults, harqFeedback] = performMACOperations(UEs, allocations, selectedMCS, channelMatrix(:, t), params, t, harqFeedback);

    for ue = 1:params.numUEs
        dataCollector.ack(t, ue) = txResults(ue).ACK;
        dataCollector.nack(t, ue) = txResults(ue).NACK;
        dataCollector.retx(t, ue) = txResults(ue).retransmissions;
    end

    if t < params.simTime
        channelMatrix(:, t+1) = updateChannelConditions(channelMatrix(:, t), params);
    end
end

fprintf('\nSimulation complete.\n');
visualizeResults(dataCollector, params);
displayPerformanceSummary(dataCollector, params);
