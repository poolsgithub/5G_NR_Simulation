function params = getUserParameters(params)
    % getUserParameters - Allows user to override default simulation parameters

    prompt = 'Enter number of UEs (default: %d): ';
    value = input(sprintf(prompt, params.numUEs));
    if ~isempty(value)
        params.numUEs = value;
    end

    prompt = 'Enter simulation time in TTIs (default: %d): ';
    value = input(sprintf(prompt, params.simTime));
    if ~isempty(value)
        params.simTime = value;
    end

    prompt = 'Select scheduler (roundRobin / maxThroughput / proportionalFair) [default: %s]: ';
    value = input(sprintf(prompt, params.schedulerType), 's');
    if ~isempty(value)
        params.schedulerType = value;
    end

    prompt = 'Enable adaptive MCS? (1 for yes, 0 for no) [default: %d]: ';
    value = input(sprintf(prompt, params.adaptiveMCS));
    if ~isempty(value)
        params.adaptiveMCS = logical(value);
    end
end
