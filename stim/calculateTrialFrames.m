function [framesPerSweep, DurationperSweep] = calculateTrialFrames(TRperSweep, TRperRest, VolumeTR, Conditions, refreshRate)
    % calculateFrames - A function that calculates how many frames you
    % exactly need to complete the experiment. There should be a timer as
    % well that times the function, as it might happen that you lose
    % frames...
    %
    % USAGE:
    % framesPerSweep = calculateFrames(Parameters.TRperSweep, Parameters.VolumeTR, length(Parameters.Conditions), refreshRate)

    % run duration 
    maxDurationperSweep = TRperSweep*VolumeTR; % Maximum duration per sweep in seconds
    maxDurationperRest = TRperRest*VolumeTR; % Maximum duration per rest in seconds


    numFramesSweep = calculateAllFrames(refreshRate, maxDurationperSweep);
    numFramesRest = calculateAllFrames(refreshRate, maxDurationperRest);

    % create a zero array in size of Conditions
    framesPerSweep = zeros(1, length(Conditions)); % Preallocate array for frames per sweep
    % Create an array of TRs based on Conditions
    TRsPerCondition = zeros(1, length(Conditions)); % Preallocate array for TRs per condition
    % Initialize the DurationperSweep array
    DurationperSweep = zeros(1, length(Conditions)); % Preallocate array for duration per sweep


    % Calculate the total number of frames for each condition
    for i = 1:length(Conditions)
        if isnan(Conditions(i))
            % If the condition is rest, use the rest duration
            numFramesCond = numFramesRest;
            TRsPerCondition(i) = TRperRest;
            DurationperSweep(i) = maxDurationperRest; % Duration for rest condition
        else
            % If the condition is not rest, use the sweep duration
            numFramesCond = numFramesSweep;
            TRsPerCondition(i) = TRperSweep;
            DurationperSweep(i) = maxDurationperSweep; % Duration for sweep condition
        end
        framesPerSweep(i) = numFramesCond; % Total frames per condition
    end
    

    % Calculate the total number of frames for the entire experiment
    numFrames = sum(framesPerSweep); % Total frames for the entire experiment

    % Calculate the number of TRs for the entire experiment
    numTR = sum(TRsPerCondition); % Total TRs for the entire experiment
    % calculate the duration of the entire experiment
    expectedDuration = numTR*VolumeTR; % Total duration in seconds
    % calculate the expected frames for the entire experiment
    expectedFrames = calculateAllFrames(refreshRate, expectedDuration); % Total frames for the entire experiment

    % get the difference between the expected frames and the calculated frames
    frameDifference = expectedFrames - numFrames; % Difference in frames
    
    % Distribute the frameDifference randomly across all conditions
    framesAdjustment = zeros(1, length(Conditions)); % Preallocate adjustment array
    randomIndices = randperm(length(Conditions)); % Generate a random permutation of condition indices
    for i = 1:abs(frameDifference)
        idx = randomIndices(mod(i-1, length(Conditions)) + 1); % Cycle through random indices
        if frameDifference > 0
            framesAdjustment(idx) = framesAdjustment(idx) + 1; % Add frames
        else
            framesAdjustment(idx) = framesAdjustment(idx) - 1; % Remove frames
        end
    end
    framesPerSweep = framesPerSweep + framesAdjustment; % Adjust frames per condition

end

%%%%%%%%%%%%%%%%%%% FUNCTIONS %%%%%%%%%%%%%%%%%%%

function numFrames = calculateAllFrames(refreshRate, durationInSeconds)
    % calculateAllFrames - Calculate the number of frames needed for an experiment
    %
    % Inputs:
    %   refreshRate - Refresh rate of the display in Hz (frames per second)
    %   durationInSeconds - Duration of the experiment in seconds
    %
    % Output:
    %   numFrames - Total number of frames required

    % Validate inputs
    if refreshRate <= 0
        error('Refresh rate must be a positive value.');
    end
    if durationInSeconds <= 0
        error('Duration must be a positive value.');
    end

    % Calculate the number of frames
    numFrames = floor(refreshRate * durationInSeconds);
end