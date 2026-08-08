function [inputIsDown, inputTime, inputCode] = ParallelCheck()
    % Check the parallel port for input - mimics KbCheck behavior
    % Returns:
    %   inputIsDown: true if any relevant input is active
    %   inputTime: time from GetSecs when input was detected
    %   inputCode: struct with logical fields for different inputs
    
    inputTime = GetSecs;
    bitCode = logical(ParallelIn());  % read 16-bit port input
    
    % Create inputCode structure similar to keyCode
    inputCode = struct();
    inputCode.Trigger = bitCode(1) || bitCode(9);     % trigger: either bit 1 or 9
    inputCode.Response = bitCode(5) || bitCode(13);                  % left index: bit 5, right index: bit 13
    
    % You can add more inputs here if needed:
    % received = [0,0,0,0,0,0,0,0]; % [trig, bnc, bnc, r_thumb, r_index, r_middle, r_ring, r_pinkie]
    % received2 = [0,0,0,0,0,0,0,0]; % [trig, bnc, bnc, l_thumb, l_index, l_middle, l_ring, l_pinkie]
    % inputCode.LeftIndex = bitCode(13);              % left index: bit 13 (example)
    % inputCode.RightThumb = bitCode(4);              % right thumb: bit 4 (example)
    
    
    % inputIsDown is true if any relevant input is active
    inputIsDown = inputCode.Trigger || inputCode.Response;
end