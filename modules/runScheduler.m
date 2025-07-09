function [allocations, selectedMCS] = runScheduler(UEs, harqFeedback, channelConditions, params)
    numUEs = length(UEs);
    allocations = zeros(numUEs, 1);
    selectedMCS = ones(numUEs, 1);

    activeUEs = [];
    for ue = 1:numUEs
        hasNewData = (UEs(ue).bsr > 0);
        hasRetransmissions = any(harqFeedback(ue).pending);
        if hasNewData || hasRetransmissions
            activeUEs(end+1) = ue;
        end
    end

    if isempty(activeUEs)
        return;
    end

    for ue = activeUEs
        if params.adaptiveMCS
            mcsIndex = max(1, min(length(params.mcsTable), ceil(channelConditions(ue) * length(params.mcsTable))));
            selectedMCS(ue) = mcsIndex;
        else
            selectedMCS(ue) = ceil(length(params.mcsTable) / 2);
        end
    end

    prbsPerUE = floor(params.bwpSize / length(activeUEs));
    for ue = activeUEs
        allocations(ue) = prbsPerUE;
    end
end
