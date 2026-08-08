% Receive scanner trigger to start
% TriggerExperimentKB waits for the trigger to start.
% 
% We're waiting for keyboard (KB) button presses. At the 9.4 T scanner in
% Tuebingen the trigger comes in as a 'q', but we're looking to change that
% to have better timing and to reliably catch trigger and button presses if
% they ariive simultaneously.

%% Tuebingen setup
% Wait for 'q' key as the trigger
disp('Using KbCheck to check for triggers. This should be changed!');

keyPressed = false;
while ~keyPressed
    [~, ~, bk] = KbCheck;
    if bk(KeyCodes.Trigger)  % Check if 'q' key is pressed
        keyPressed = true;
        disp('Received dummy trigger. Starting experiment in TR * Dummies!'); %, num2str(i), ' of ', num2str(Parameters.Dummies)]);

    end
end