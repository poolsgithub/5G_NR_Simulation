function visualizeResults(dataCollector, params)
    % BAR GRAPHS — ACKs, NACKs, Retransmissions per TTI
    figure;
    bar(dataCollector.ack, 'stacked');
    title('ACKs per TTI');
    xlabel('TTI'); ylabel('ACKs');

    figure;
    bar(dataCollector.nack, 'stacked');
    title('NACKs per TTI');
    xlabel('TTI'); ylabel('NACKs');

    figure;
    bar(dataCollector.retx, 'stacked');
    title('Retransmissions per TTI');
    xlabel('TTI'); ylabel('Count');

    % TOTALS FOR PIE CHART
    totalACKs  = sum(dataCollector.ack, 'all');
    totalNACKs = sum(dataCollector.nack, 'all');
    totalRetx  = sum(dataCollector.retx, 'all');
    totalTX    = totalACKs + totalNACKs;

    % PIE CHART: ACK vs NACK
    figure;
    pie([totalACKs, totalNACKs], {'ACK', 'NACK'});
    title('ACK vs NACK Distribution');

    % PIE CHART: Initial TX vs Retransmissions
    if totalTX > 0
        successfulInitialTX = totalTX - totalRetx;
        figure;
        pie([successfulInitialTX, totalRetx], {'Initial TX Success', 'Retransmissions'});
        title('Transmission Attempts Distribution');
    end
end
