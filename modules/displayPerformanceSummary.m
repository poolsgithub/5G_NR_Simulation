function displayPerformanceSummary(dataCollector, params)
    totalACKs = sum(dataCollector.ack, 'all');
    totalNACKs = sum(dataCollector.nack, 'all');
    totalRetx  = sum(dataCollector.retx, 'all');

    fprintf('\n--- Performance Summary ---\n');
    fprintf('Total ACKs:  %d\n', totalACKs);
    fprintf('Total NACKs: %d\n', totalNACKs);
    fprintf('Total Retransmissions: %d\n', totalRetx);
end
