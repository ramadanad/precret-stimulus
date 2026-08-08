% Receive scanner trigger to start
% TriggerExperimentPP waits for the trigger to start.
% This uses parallelPort (PP) 
% We're checking the parallel port input

%% Tuebingen setup
% 20250801: added parallelPort

% Using parallel port
disp ('Yay! Parallel port!')
disp('Waiting for dummy trigger...');


% -------- Actual Wait-for-Trigger Phase --------
triggerPressed = false;
while ~triggerPressed
% % If using parallel port
            [inputIsDown, inputTime, inputCode] = ParallelCheck;
            if inputIsDown && inputCode.Trigger && ~triggerPressed %&& inputTime - Trigger.Time(end) > Parameters.VolumeTR - 1
                    % Save the time of the trigger
                    disp('Received dummy trigger. Starting experiment in TR * Dummies!'); %, num2str(i), ' of ', num2str(Parameters.Dummies)]);
                    Trigger.Number = Trigger.Number + Parameters.Dummies;
                    triggerPressed = true;
            else
                triggerPressed = false;
            end
            WaitSecs(0.001); % 1ms to avoid CPU overload!!!
end