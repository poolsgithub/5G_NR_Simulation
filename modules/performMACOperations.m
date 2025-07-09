function [UEs, txResults, harqFeedback] = performMACOperations(UEs, allocations, selectedMCS, channelConditions, params, tti, harqFeedback)
    % performMACOperations - Handles transmissions and HARQ feedback

    numUEs = length(UEs);

    % Initialize txResults for every UE to avoid indexing errors
    txResults = repmat(struct('ACK', false, 'NACK', false, 'retransmissions', 0), numUEs, 1);

    for ue = 1:numUEs
        if allocations(ue) > 0
            % Assume a simple probability of success based on channel quality
            successProb = channelConditions(ue);  % Between 0 and 1
            isSuccess = rand < successProb;

            if isSuccess
                % Successful transmission
                txResults(ue).ACK = true;
                UEs(ue).bsr = max(0, UEs(ue).bsr - allocations(ue));  % Reduce buffer
                harqFeedback(ue).pending(:) = false;  % Clear HARQ
            else
                % Failed transmission → NACK + HARQ
                txResults(ue).NACK = true;
                txResults(ue).retransmissions = txResults(ue).retransmissions + 1;

                % Mark HARQ pending
                if isfield(harqFeedback(ue), 'pending')
                    harqFeedback(ue).pending(1) = true;  % Simplified to 1 process
                end
            end
        end
    end
end
