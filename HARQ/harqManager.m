function [HARQEntry, ackSuccess, eventLog] = harqManager(currentHARQ, ackProb, maxRetrans)
    eventLog = "";
    isNewTx = currentHARQ.Status == "IDLE" || currentHARQ.Status == "ACK";
    success = rand() < ackProb;

    if isNewTx
        if success
            HARQEntry = struct('RV', 0, 'Status', "ACK", 'Retransmissions', 0);
            ackSuccess = true;
            eventLog = "New TX SUCCESS";
        else
            HARQEntry = struct('RV', 1, 'Status', "NACK", 'Retransmissions', 1);
            ackSuccess = false;
            eventLog = "New TX FAILED";
        end
    else
        if currentHARQ.Retransmissions >= maxRetrans
            HARQEntry = struct('RV', 0, 'Status', "IDLE", 'Retransmissions', 0);
            ackSuccess = false;
            eventLog = sprintf("Dropped after %d retx", maxRetrans);
        elseif success
            HARQEntry = struct('RV', 0, 'Status', "ACK", 'Retransmissions', 0);
            ackSuccess = true;
            eventLog = sprintf("Retx SUCCESS (RV=%d)", currentHARQ.RV);
        else
            HARQEntry = struct('RV', currentHARQ.RV + 1, 'Status', "NACK", ...
                               'Retransmissions', currentHARQ.Retransmissions + 1);
            ackSuccess = false;
            eventLog = sprintf("Retx FAILED (RV=%d)", currentHARQ.RV + 1);
        end
    end
end
