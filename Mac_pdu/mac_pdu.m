% Function to construct a MAC PDU
function macPDU = createMacPDU(LCID, payload, tbSize)
    % Header (LCID and Length)
    lcidField = uint8(LCID);
    lengthField = uint8(length(payload));
    
    % Combine fields
    macPDU = [lcidField, lengthField, uint8(payload)];
    
    % Padding if needed
    paddingLength = tbSize - length(macPDU);
    if paddingLength > 0
        macPDU = [macPDU, zeros(1, paddingLength, 'uint8')];
    end
end

% Function to parse a MAC PDU
function parseMacPDU(macPDU)
    lcid = macPDU(1);
    len  = macPDU(2);
    payload = macPDU(3:2+len);
    
    fprintf('Parsed MAC PDU:\n');
    fprintf('  LCID    : %d\n', lcid);
    fprintf('  Length  : %d bytes\n', len);
    fprintf('  Payload : %s\n', char(payload));
    
    if length(macPDU) > 2 + len
        fprintf('  Padding : %d bytes\n', length(macPDU) - (2 + len));
    end
end

% --- Usage Example ---

% Inputs
LCID = 1;                                % Logical Channel ID
payload = 'HelloMAC';                   % Payload from RLC or control
tbSize = 16;                            % Transport block size (bytes)

% Create MAC PDU
macPDU = createMacPDU(LCID, payload, tbSize);

% Display the MAC PDU as hex
fprintf('MAC PDU (hex): ');
disp(dec2hex(macPDU));

% Parse it back
parseMacPDU(macPDU);
