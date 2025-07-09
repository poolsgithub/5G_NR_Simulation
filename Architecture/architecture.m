% 5G NR MAC Protocol Simulation
% Step-by-step implementation with performance metrics and visualization

clear all;
close all;



%% Simulation Parameters
disp('Step 1: Setting up simulation parameters...');
simTime = 1000;           % Total simulation time in TTIs (Transmission Time Intervals)
numUEs = 10;              % Number of UEs (User Equipment)
bwpSize = 100;            % Bandwidth part size in PRBs (Physical Resource Blocks)
mcsTable = [0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8, 2.0]; % Spectral efficiency for MCS levels
harqProcesses = 8;        % Number of HARQ processes per UE
maxHarqRetx = 4;          % Maximum HARQ retransmissions
bsrPeriod = 5;            % BSR reporting period in TTIs

%% Initialize Data Collection
throughputPerUE = zeros(numUEs, simTime);      % Throughput per UE per TTI
cellThroughput = zeros(1, simTime);            % Cell throughput per TTI
ueBufferStatus = zeros(numUEs, simTime);       % Buffer status per UE per TTI
scheduledUEs = zeros(numUEs, simTime);         % Scheduled UEs per TTI
latencyPerPacket = cell(numUEs, 1);            % Latency measurements for each packet
harqRetransmissions = zeros(numUEs, simTime);  % HARQ retransmissions per UE per TTI
resourceUtilization = zeros(1, simTime);       % PRB utilization per TTI

%% Initialize Network Elements
disp('Step 2: Initializing network elements...');

% gNB configuration
gNB = struct();
gNB.schedulerType = 'proportionalFair';  % Options: 'roundRobin', 'maxThroughput', 'proportionalFair'
gNB.dlBuffers = zeros(numUEs, 1);        % Downlink buffers for each UE
gNB.harqBuffers = cell(numUEs, harqProcesses);  % HARQ buffers for each UE and process
gNB.harqProcessStatus = zeros(numUEs, harqProcesses);  % 0 for available, 1 for in use
gNB.harqRetxCount = zeros(numUEs, harqProcesses);      % Count of retransmissions

% UE configuration
UEs = struct();
for ue = 1:numUEs
    UEs(ue).id = ue;
    UEs(ue).buffer = 0;                          % UL buffer size in bytes
    UEs(ue).bsr = 0;                             % Buffer Status Report
    UEs(ue).harqProcesses = cell(1, harqProcesses);  % HARQ processes
    UEs(ue).harqStatus = zeros(1, harqProcesses);    % HARQ status
    UEs(ue).packets = struct('arrivalTime', [], 'size', [], 'deliveryTime', [], 'latency', []);
    UEs(ue).currentHarqProcess = 1;                  % Current HARQ process
    UEs(ue).channelQuality = 0.7 + 0.2*rand();       % Initial channel quality (0-1)
    UEs(ue).averageThroughput = 0;                   % For PF scheduler
end

%% Traffic Model Parameters
disp('Step 3: Setting up traffic models...');
trafficModel = 'poisson';  % Options: 'poisson', 'fullBuffer', 'cbr'
arrivalRate = 10;          % Average packet arrival rate (packets per TTI)
packetSizeAvg = 1500;      % Average packet size in bytes
packetSizeStd = 500;       % Standard deviation of packet size

%% Channel Model
disp('Step 4: Setting up channel models...');
% Simple channel model with correlation in time
channelMatrix = zeros(numUEs, simTime);
for ue = 1:numUEs
    % Initialize channel with random quality
    channelMatrix(ue, 1) = UEs(ue).channelQuality;
    
    % Generate correlated channel conditions for the simulation period
    for t = 2:simTime
        % Simple channel model with temporal correlation
        channelMatrix(ue, t) = 0.95 * channelMatrix(ue, t-1) + 0.05 * rand();
        % Ensure channel quality is between 0 and 1
        channelMatrix(ue, t) = max(0.1, min(1.0, channelMatrix(ue, t)));
    end
end

%% Main Simulation Loop
disp('Step 5: Starting main simulation loop...');
for t = 1:simTime
    if mod(t, 100) == 0
        disp(['Simulation progress: ' num2str(t/simTime*100) '%']);
    end
    
    %% Traffic Generation
    % Generate new traffic for each UE based on the traffic model
    for ue = 1:numUEs
        % Traffic generation
        if strcmp(trafficModel, 'poisson')
            numNewPackets = poissrnd(arrivalRate/numUEs);  % Poisson traffic model
        elseif strcmp(trafficModel, 'fullBuffer')
            numNewPackets = 1;  % Always have data to transmit
        elseif strcmp(trafficModel, 'cbr')
            numNewPackets = (mod(t, 10) == 0);  % Constant bit rate, every 10 TTIs
        end
        
        % Add packets to UE buffer
        for p = 1:numNewPackets
            packetSize = max(100, normrnd(packetSizeAvg, packetSizeStd));
            UEs(ue).buffer = UEs(ue).buffer + packetSize;
            
            % Record packet arrival for latency calculation
            packetIdx = length(UEs(ue).packets.arrivalTime) + 1;
            UEs(ue).packets.arrivalTime(packetIdx) = t;
            UEs(ue).packets.size(packetIdx) = packetSize;
            UEs(ue).packets.deliveryTime(packetIdx) = NaN;  % Not delivered yet
            UEs(ue).packets.latency(packetIdx) = NaN;       % Latency not calculated yet
        end
        
        % Store buffer status for visualization
        ueBufferStatus(ue, t) = UEs(ue).buffer;
    end
    
    %% BSR Generation
    % Generate and send Buffer Status Reports periodically
    if mod(t, bsrPeriod) == 0
        for ue = 1:numUEs
            UEs(ue).bsr = UEs(ue).buffer;  % Simplified BSR
        end
    end
    
    %% Scheduling
    % Run the scheduler to allocate resources
    [allocations, selectedMCS] = runScheduler(gNB, UEs, channelMatrix(:, t), bwpSize, mcsTable);
    
    % Calculate resource utilization
    resourceUtilization(t) = sum(allocations) / bwpSize;
    
    %% MAC Operations and HARQ
    for ue = 1:numUEs
        % If UE is scheduled in this TTI
        if allocations(ue) > 0
            scheduledUEs(ue, t) = 1;
            
            % Calculate the transport block size based on allocation and MCS
            tbs = allocations(ue) * mcsTable(selectedMCS(ue));
            
            % Simulate transmission
            txBytes = min(tbs, UEs(ue).buffer);
            UEs(ue).buffer = UEs(ue).buffer - txBytes;
            
            % Select HARQ process
            harqProcess = UEs(ue).currentHarqProcess;
            UEs(ue).harqProcesses{harqProcess} = txBytes;
            UEs(ue).harqStatus(harqProcess) = 1;  % Mark as in use
            
            % Simulate reception (success probability based on channel quality)
            channelQuality = channelMatrix(ue, t);
            successProb = channelQuality * (0.8 + 0.2 * selectedMCS(ue) / length(mcsTable));
            success = (rand() < successProb);
            
            if success
                % Transmission successful
                throughputPerUE(ue, t) = txBytes;
                
                % Update packet delivery information for latency calculation
                remainingBytes = txBytes;
                packetIndices = find(isnan(UEs(ue).packets.deliveryTime));
                
                for idx = packetIndices
                    packetSize = UEs(ue).packets.size(idx);
                    if remainingBytes >= packetSize
                        % Full packet delivered
                        UEs(ue).packets.deliveryTime(idx) = t;
                        UEs(ue).packets.latency(idx) = t - UEs(ue).packets.arrivalTime(idx);
                        remainingBytes = remainingBytes - packetSize;
                        
                        % Store latency information
                        latencyPerPacket{ue} = [latencyPerPacket{ue}, UEs(ue).packets.latency(idx)];
                    else
                        % Partial packet delivery (simplified model)
                        % We don't handle partial packets in this model
                        break;
                    end
                    
                    if remainingBytes <= 0
                        break;
                    end
                end
                
                % Reset HARQ process
                UEs(ue).harqStatus(harqProcess) = 0;
            else
                % Transmission failed, schedule retransmission
                harqRetransmissions(ue, t) = 1;
                % HARQ process remains active for retransmission
            end
            
            % Move to next HARQ process
            UEs(ue).currentHarqProcess = mod(UEs(ue).currentHarqProcess, harqProcesses) + 1;
        end
        
        % Handle HARQ retransmissions
        for hp = 1:harqProcesses
            if UEs(ue).harqStatus(hp) == 1 && hp ~= UEs(ue).currentHarqProcess
                % This is a pending HARQ process - in a more detailed model, 
                % we would schedule retransmissions with proper timing
                % For simplicity, we're not implementing the full HARQ timing procedures
            end
        end
        
        % Update PF scheduler metric
        if throughputPerUE(ue, t) > 0
            UEs(ue).averageThroughput = 0.9 * UEs(ue).averageThroughput + 0.1 * throughputPerUE(ue, t);
        else
            UEs(ue).averageThroughput = 0.9 * UEs(ue).averageThroughput;
        end
    end
    
    % Calculate cell throughput
    cellThroughput(t) = sum(throughputPerUE(:, t));
end

disp('Step 6: Simulation completed. Generating visualizations...');

%% Post-processing and Visualization
% Apply moving average for smoothing
windowSize = 20;
smoothCellThroughput = movmean(cellThroughput, windowSize);

% Calculate statistics
avgCellThroughput = mean(cellThroughput);
avgUEThroughput = mean(sum(throughputPerUE, 2) / simTime);
avgResourceUtil = mean(resourceUtilization);

% Calculate average latency per UE
avgLatency = zeros(numUEs, 1);
for ue = 1:numUEs
    if ~isempty(latencyPerPacket{ue})
        avgLatency(ue) = mean(latencyPerPacket{ue});
    else
        avgLatency(ue) = NaN;
    end
end

% Visualization
figure('Name', '5G NR MAC Performance Metrics', 'Position', [100, 100, 1200, 800]);

% 1. Cell Throughput Over Time
subplot(2, 3, 1);
plot(1:simTime, smoothCellThroughput, 'LineWidth', 2);
title('Cell Throughput Over Time');
xlabel('TTI');
ylabel('Throughput (bytes)');
grid on;

% 2. Average UE Throughput
subplot(2, 3, 2);
bar(1:numUEs, avgUEThroughput);
title('Average UE Throughput');
xlabel('UE ID');
ylabel('Avg. Throughput (bytes/TTI)');
grid on;

% 3. Resource Utilization
subplot(2, 3, 3);
plot(1:simTime, movmean(resourceUtilization * 100, windowSize), 'LineWidth', 2);
title('Resource Block Utilization');
xlabel('TTI');
ylabel('Utilization (%)');
ylim([0, 100]);
grid on;

% 4. Buffer Status Over Time
subplot(2, 3, 4);
plot(1:simTime, movmean(ueBufferStatus', windowSize));
title('UE Buffer Status Over Time');
xlabel('TTI');
ylabel('Buffer Size (bytes)');
grid on;
legend(arrayfun(@(x) ['UE ' num2str(x)], 1:min(5, numUEs), 'UniformOutput', false), 'Location', 'northeast');


% 6. HARQ Retransmissions
subplot(2, 3, 6);
totalHarqRetx = sum(harqRetransmissions, 2);
bar(1:numUEs, totalHarqRetx);
title('Total HARQ Retransmissions per UE');
xlabel('UE ID');
ylabel('Number of Retransmissions');
grid on;

% Create a figure for scheduling visualization
figure('Name', 'Resource Allocation Visualization', 'Position', [100, 100, 1200, 400]);
imagesc(scheduledUEs);
colormap([1 1 1; 0 0.7 0]);
title('Resource Allocation Over Time');
xlabel('TTI');
ylabel('UE ID');
colorbar('Ticks', [0.25, 0.75], 'TickLabels', {'Not Scheduled', 'Scheduled'});

% Summary statistics display
disp('=== Simulation Results Summary ===');
disp(['Average Cell Throughput: ' num2str(avgCellThroughput) ' bytes/TTI']);
disp(['Average Resource Utilization: ' num2str(avgResourceUtil * 100) '%']);
disp(['Average UE Throughput: ' num2str(mean(avgUEThroughput)) ' bytes/TTI']);


%% Helper Functions
function [alloc, selectedMCS] = runScheduler(gNB, UEs, channelConditions, totalPRBs, mcsTable)
    numUEs = length(UEs);
    alloc = zeros(numUEs, 1);
    selectedMCS = ones(numUEs, 1);  % Default to lowest MCS
    
    % Extract scheduling metrics based on scheduler type
    if strcmp(gNB.schedulerType, 'roundRobin')
        % Round Robin scheduler - equal share to all UEs with data
        activeUEs = find([UEs.bsr] > 0);
        numActiveUEs = length(activeUEs);
        
        if numActiveUEs > 0
            prbsPerUE = floor(totalPRBs / numActiveUEs);
            for i = 1:numActiveUEs
                ue = activeUEs(i);
                alloc(ue) = prbsPerUE;
                
                % Select appropriate MCS based on channel conditions
                mcsIndex = max(1, min(length(mcsTable), ceil(channelConditions(ue) * length(mcsTable))));
                selectedMCS(ue) = mcsIndex;
            end
        end
        
    elseif strcmp(gNB.schedulerType, 'maxThroughput')
        % Maximum Throughput scheduler - allocate to UEs with best channel conditions
        metrics = zeros(numUEs, 1);
        for ue = 1:numUEs
            if UEs(ue).bsr > 0
                % Select appropriate MCS based on channel conditions
                mcsIndex = max(1, min(length(mcsTable), ceil(channelConditions(ue) * length(mcsTable))));
                selectedMCS(ue) = mcsIndex;
                
                % Calculate potential throughput
                metrics(ue) = channelConditions(ue) * mcsTable(mcsIndex);
            end
        end
        
        % Sort UEs by metrics (descending)
        [~, sortedUEs] = sort(metrics, 'descend');
        
        % Allocate resources based on metrics
        remainingPRBs = totalPRBs;
        for i = 1:numUEs
            ue = sortedUEs(i);
            if metrics(ue) > 0 && remainingPRBs > 0
                % Calculate PRBs needed based on buffer size and MCS
                prbsNeeded = min(remainingPRBs, ceil(UEs(ue).bsr / mcsTable(selectedMCS(ue))));
                alloc(ue) = prbsNeeded;
                remainingPRBs = remainingPRBs - prbsNeeded;
            end
        end
        
    elseif strcmp(gNB.schedulerType, 'proportionalFair')
        % Proportional Fair scheduler - balance throughput and fairness
        metrics = zeros(numUEs, 1);
        for ue = 1:numUEs
            if UEs(ue).bsr > 0
                % Select appropriate MCS based on channel conditions
                mcsIndex = max(1, min(length(mcsTable), ceil(channelConditions(ue) * length(mcsTable))));
                selectedMCS(ue) = mcsIndex;
                
                % Calculate PF metric: instantaneous rate / average throughput
                instantRate = channelConditions(ue) * mcsTable(mcsIndex);
                if UEs(ue).averageThroughput > 0
                    metrics(ue) = instantRate / UEs(ue).averageThroughput;
                else
                    metrics(ue) = instantRate;
                end
            end
        end
        
        % Allocate resources based on PF metrics
        remainingPRBs = totalPRBs;
        while remainingPRBs > 0
            [maxMetric, bestUE] = max(metrics);
            if maxMetric == 0
                break;  % No more UEs to schedule
            end
            
            % Calculate PRBs needed based on buffer size and MCS
            prbsNeeded = min(remainingPRBs, ceil(UEs(bestUE).bsr / mcsTable(selectedMCS(bestUE))));
            if prbsNeeded == 0
                prbsNeeded = 1;  % Allocate at least one PRB
            end
            
            alloc(bestUE) = alloc(bestUE) + prbsNeeded;
            remainingPRBs = remainingPRBs - prbsNeeded;
            metrics(bestUE) = 0;  % Prevent re-allocation to this UE in this TTI
        end
    end
end