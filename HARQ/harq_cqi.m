function results = harq_cqi(numUEs, numTTIs, ackProb, seed)

if nargin < 1, numUEs = 5; end
if nargin < 2, numTTIs = 100; end
if nargin < 3, ackProb = 0.65; end
if nargin < 4, seed = randi(1000); end
rng(seed); % Ensure reproducibility

harqProcesses = 4;
maxRetrans = 3;
throughputWindow = 10;

% Init UE buffers
UEBuffer = struct();
for ue = 1:numUEs
    UEBuffer(ue).bsr = 0;
end

% Init HARQ buffer
HARQBuffer = repmat(struct('RV', 0, 'Status', "IDLE", 'Retransmissions', 0), harqProcesses, numUEs);

% gNB Stats
gNB.ackCount = zeros(1, numUEs);
gNB.nackCount = zeros(1, numUEs);
gNB.retxCount = zeros(1, numUEs);

% CQI and throughput tracking
CQI = randi([5 15], 1, numUEs);
avgThroughput = zeros(1, numUEs);
CQI_trace = zeros(numTTIs, numUEs); % Store CQI per TTI

% TTI simulation loop
for tti = 1:numTTIs
    % Generate traffic
    for ue = 1:numUEs
        UEBuffer(ue).bsr = UEBuffer(ue).bsr + randi([0 3]);
    end

    % Randomly update CQI every 5 TTIs
    if mod(tti, 5) == 0
        CQI = max(1, min(15, CQI + randi([-2 2], 1, numUEs)));
        CQI_trace(tti, :) = CQI; % Record CQI at this TTI
    end

    % Compute PF metric
    PFmetric = zeros(1, numUEs);
    for ue = 1:numUEs
        if UEBuffer(ue).bsr > 0
            PFmetric(ue) = CQI(ue) / (avgThroughput(ue) + 1);
        else
            PFmetric(ue) = -inf;
        end
    end

    [~, scheduledUE] = max(PFmetric);
    harqID = mod(tti - 1, harqProcesses) + 1;

    % Skip if no data
    if UEBuffer(scheduledUE).bsr == 0
        fprintf('TTI %3d | UE %d | No Data to Send\n', tti, scheduledUE);
        continue;
    end

    % HARQ process
    currentHARQ = HARQBuffer(harqID, scheduledUE);
    [updatedHARQ, ~, log] = harqManager(currentHARQ, ackProb, maxRetrans);
    HARQBuffer(harqID, scheduledUE) = updatedHARQ;

    fprintf('TTI %3d | UE %d | HARQ %d | CQI %2d | %s\n', ...
            tti, scheduledUE, harqID, CQI(scheduledUE), log);

    % Update stats
    if updatedHARQ.Status == "ACK"
        gNB.ackCount(scheduledUE) = gNB.ackCount(scheduledUE) + 1;
        UEBuffer(scheduledUE).bsr = max(UEBuffer(scheduledUE).bsr - 1, 0);
        avgThroughput(scheduledUE) = (1 - 1/throughputWindow) * avgThroughput(scheduledUE) + (1/throughputWindow);
    elseif updatedHARQ.Status == "NACK"
        gNB.nackCount(scheduledUE) = gNB.nackCount(scheduledUE) + 1;
        gNB.retxCount(scheduledUE) = gNB.retxCount(scheduledUE) + 1;
    end
end

% Final summary printout
fprintf('\n--- Simulation Summary ---\n');
for ue = 1:numUEs
    fprintf('UE %d: ACK = %d, NACK = %d, RETX = %d, Final BSR = %d, CQI = %d\n', ...
        ue, gNB.ackCount(ue), gNB.nackCount(ue), gNB.retxCount(ue), UEBuffer(ue).bsr, CQI(ue));
end

% Plot bar charts
figure; bar(gNB.ackCount); title('ACKs per UE'); xlabel('UE'); ylabel('ACK Count'); grid on;
figure; bar(gNB.nackCount); title('NACKs per UE'); xlabel('UE'); ylabel('NACK Count'); grid on;
figure; bar(gNB.retxCount); title('Retransmissions per UE'); xlabel('UE'); ylabel('Count'); grid on;
figure; bar([UEBuffer.bsr]); title('Final BSR per UE'); xlabel('UE'); ylabel('Buffer Size'); grid on;
figure; bar(CQI); title('Final CQI per UE'); xlabel('UE'); ylabel('CQI'); grid on;



% Return results to caller
results = struct('ack', gNB.ackCount, ...
                 'nack', gNB.nackCount, ...
                 'retx', gNB.retxCount, ...
                 'finalBSR', [UEBuffer.bsr], ...
                 'CQI', CQI);
end
