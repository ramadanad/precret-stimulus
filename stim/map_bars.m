function map_bars(Parameters, SaveAps)
% This function highly relies on Samsrf's function Bars_Mapping.m located
% in the Common_Functions folder
% However, there are some changes to the function that mostly have to do
% with the following:t
%       1) Timing: CurrFrame dictates the length of a specific trial
%       2) 2 Bars design:
%           This function now allows either the use of 2 Bars 
%           However, please use with care!
%       3) Different active vs. rest periods:
%           You can now choose, whether you want a different number of TRs
%           during the active or the rest period.
%       4) Some minor adjustments, that I (don't) need at my current setup
%           in Tuebingen at the 9.4 T scanner :)
%
%   Inputs:
%       Parameters  -   A structure that includes all necessary parameters 
%       to run this function
%       SaveAps     -   Do you want to save the aperture for later use in
%       the modeling of the pRFs? You should only set this to 1 OUTSIDE of
%       your normal experiment. If this is one, it causes weird
%       (intentional) flips and also critical timing issues. Always set to
%       0 if your running the real experiment
%
%   This function is usually run with the funcrion called bars_dr.m
%   You define your Parameters there and then run it from there:)
%
% DR TODO: Fix downsampling! It is not working properly anymore!

% Some explanations:
% A "sweep" is when a bar is sweeping through the visual field
% A "rest" is when no bar is shown
% A "trial" is either a sweep or rest 
% A "volume" is how long a bar stays in one position and also refers to an
% fMRI volume



% Go to folder of calling wrapper function
GoToCurrFunc; 

% Create the mandatory Results folder if not already present 
if ~exist([cd filesep 'Results'], 'dir')
    mkdir('Results');
end

%% Initialize randomness & keycodes
SetupRand; %DR: checked
SetupKeyCodes; %DR: added Trigger
parallelPort = checkParportExistence();

%% Behavioral and Trigger data
Behavior.ResponseTime = [];
Trigger.Time = 0;
Trigger.Number = 0;
correctedVols = 0;
keyTime = -Inf;   % First key press was before the Big Bang 

%% Event timings 
% DR: How many fmri volumes do we expect? Now for one bar
Parameters.TotalVolumes = Parameters.Dummies + sum(Parameters.VolsPerTrial); % These are the total volumes you need including the dummies in the beginning, this is how many volumes you should acquire with your fMRI sequence
Parameters.ExptDuration = sum(Parameters.VolsPerTrial*Parameters.VolumeTR); % expected experiment duration without dummies
Parameters.RunDuration = Parameters.ExptDuration + Parameters.Dummies*Parameters.VolumeTR; % entire run duration with dummies
fprintf('You need %d volumes. And one run will be %d minutes and %.2f seconds\n.', Parameters.TotalVolumes, floor(Parameters.RunDuration / 60), mod(Parameters.RunDuration, 60));

% DR: Aka when fixation point changes color, fixed from the beginning &
% shouldn't be longer than the experiment duration
Behavior.EventTime = [];
for e = Parameters.VolumeTR : Parameters.Event_Duration : Parameters.ExptDuration
    if rand < Parameters.Prob_of_Event
        Behavior.EventTime = [Behavior.EventTime; e];
    end
end
% Add a dummy event at the end of the Universe
Behavior.EventTime = [Behavior.EventTime; Inf];

%% Initialize PTB
if ~isfield(Parameters, 'Gamma')
    Parameters.Gamma = 1; % If gamma undefined, don't use; DR: decoding gamma of VPixx PROPixx projector is 1, so no need to set it
end
Screen('Preference', 'SkipSyncTests', 0); % This is nice to know everything is synced correctly
PsychImaging('PrepareConfiguration'); %
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma');
Screen('Preference', 'VBLTimestampingMode', -1); % Let Psychtoolbox auto-decide, but fall back to VBL if beamposition is unreliable.
[Win, Rect] = PsychImaging('OpenWindow', Parameters.Screen, Parameters.Background, Parameters.Resolution, 32);%, [], 32); %Parameters.Resolution, 32); No need to specify the 32 bits per pixel... it is the default!

% For better timing:
% Measure the vertical refresh rate of the monitor
ifi = Screen('GetFlipInterval',Win); %inter-frame interval

% Retreive the maximum priority number
topPriorityLevel = MaxPriority(Win);
Priority(topPriorityLevel);

% DR added to save the flickering frequency in Parameters.FlickerFreq
refreshRate = Screen('NominalFrameRate', Win); % Get the refresh rate
Parameters.FlickerFreq = refreshRate / (2*Parameters.Refreshs_per_Stim);
disp(['Flickering frequency of checkerboard is: ', num2str(Parameters.FlickerFreq, '%.2f'), ' Hz']);


PsychColorCorrection('SetEncodingGamma', Win, Parameters.Gamma); % Apply desired gamma correction
disp(['Applying gamma correction = ' n2s(Parameters.Gamma)]);
% Set font style and size
Screen('TextFont', Win, Parameters.FontName);
Screen('TextSize', Win, Parameters.FontSize);
Screen('BlendFunction', Win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
HideCursor; %Nobody wants to see that

%% Get the frames per trial and the maximum duration
% This function calculates the frames needed per trial and
% the maximum duration per Trial that should not be exceeded
[framesPerTrial, ~] = calculateTrialFrames(Parameters.TRperSweep, Parameters.TRperRest, Parameters.VolumeTR, Parameters.Conditions, refreshRate); 
framesPerVolume = floor(max(framesPerTrial) / Parameters.VolsPerSweep)-1; % how many frames in a volume? aka how many frames per bar position
% Explanation: Removing one frame gets me much better timing! 

FrameRect = [0 0 repmat(Parameters.StimRect(4), 1, 2)]; %DR: changed that from Rect(4) to Parameters.StimRect(4)
flipTimesRun = nan(1, sum(framesPerTrial)); % Store flip times 
idx_vbl = 1; % Index for flip times

% Load background movie
BgdTextures = [];
if length(size(Parameters.Stimulus)) < 4
    for f = 1:size(Parameters.Stimulus, 3)
        BgdTextures(f) = Screen('MakeTexture', Win, Parameters.Stimulus(:,:,f));
    end
else
    for f = 1:size(Parameters.Stimulus, 4)
        BgdTextures(f) = Screen('MakeTexture', Win, Parameters.Stimulus(:,:,:,f));
    end
end


%% Initialize circular Aperture
CircAperture = Screen('MakeTexture', Win, 127 * ones(Parameters.StimRect([3 3])));

if SaveAps == 1
    ApFrm = zeros(100, 100, sum(Parameters.VolsPerTrial)); % Preallocate for the number of volumes
    ApFrmIdx = circshift(cumsum(Parameters.VolsPerTrial), 1);
    ApFrmIdx(1) = 0;
end
%% Standby screen
Screen('FillRect', Win, Parameters.Background, Rect);
DrawFormattedText(Win, [Parameters.Welcome '\n \n' Parameters.Instruction '\n \n' 'Stand by for scan...'], 'center', 'center', Parameters.Foreground); 
Screen('Flip', Win);
disp('***************************************************************************************');
disp(strrep([Parameters.Welcome '\n' Parameters.Instruction '\n' 'Stand by for scan...'], '\n', newline));
new_line;

% Wait for trigger to start
if parallelPort
    TriggerExperimentPP; % use the parallel port to check for trigger
else
    TriggerExperimentKB; % wait for a 'q' as trigger
end
%% Dummy volumes
Screen('FillRect', CircAperture, Parameters.Background);    % _

% Draw fixation dot
Screen('FillOval', Win, Parameters.Event_Colour(2,:), CenterRect([0 0 Parameters.Fixation_Width(1) Parameters.Fixation_Width(1)], Rect));
vbl = Screen('Flip', Win);
WaitSecs(Parameters.Dummies * Parameters.VolumeTR); % Wait for dummy volumes
StartofExperiment = GetSecs; % Start time for the experiment

buttonPressed = false; % no pressed buttons..
triggerPressed = false; % Reset trigger pressed flag



%% Stimulus presentation
% Main trial loop
for Trial = 1 : length(framesPerTrial)
    waitTimePP = 0;
    CurrFrame = 1;
    CurrVolume = 1; PrevVolume = 0; 
    % flipTimes = zeros(1, framesPerTrial(Trial)-1); % Store flip times    
    StartofTrial = GetSecs; % Start time for the trial
    % Initialize the stimulus condition
    CurrCondit = Parameters.Conditions(Trial);
    new_line; disp([Trial CurrCondit]);

    while CurrFrame <= framesPerTrial(Trial)-1 % for better timing
        
        % Check if it's time to update the stimulus
        % Determine the current block number (each block is 6 elements)
        block = ceil(CurrFrame / Parameters.Refreshs_per_Stim);
        if mod(block, 2) == 1 
            CurrStim = 1;
        else % this is responsible for the inversion
            CurrStim = 2;
        end

        % 
        % Create Aperture
        Screen('FillRect', CircAperture, [Parameters.Background 0]);    % _
        if isnan(CurrCondit) 
            Screen('FillRect', CircAperture, Parameters.Background);    % _
        elseif Parameters.NumBars == 1    
            BarRect = [0 0 Parameters.BarPos(CurrVolume)-Parameters.Bar_Width/2 Parameters.StimRect(4)];
            BarRect(BarRect <= 0) = 1;
            Screen('FillRect', CircAperture, Parameters.Background, BarRect); %this rectangle pushes in the direction of the sweep, it gets bigger with every step
            
            BarRect = [Parameters.BarPos(CurrVolume)+Parameters.Bar_Width/2 0 Parameters.StimRect(3) Parameters.StimRect(4)];
            BarRect(BarRect >= Parameters.StimRect(3)) = Parameters.StimRect(3); %this rectangle covers most of the circ aperture at first, and becomes smaller with each step
            Screen('FillRect', CircAperture, Parameters.Background, BarRect);
        else    
            BarRect = [0 0 Parameters.BarPos(CurrVolume)-Parameters.Bar_Width/2 Parameters.StimRect(4)];
            BarRect(BarRect <= 0) = 1;
            Screen('FillRect', CircAperture, Parameters.Background, BarRect); 
            
            BarRect = [Parameters.BarPos(CurrVolume)+Parameters.StimRect(3)/2+Parameters.Bar_Width/2 0 Parameters.StimRect(3) Parameters.StimRect(4)];
            BarRect(BarRect >= Parameters.StimRect(3)) = Parameters.StimRect(3);
            Screen('FillRect', CircAperture, Parameters.Background, BarRect);
            
            % Divider 
  
            DividerWidth = Parameters.StimRect(3)/2 - Parameters.Bar_Width; % The divider should be as big as half the screen - the bar width
            DividerPos = Parameters.BarPos(CurrVolume)+Parameters.Bar_Width/2; % Positioned relative to the current volume
            % Draw the second bar within the aperture
            DividerRect1 = [DividerPos 0 DividerPos+DividerWidth Parameters.StimRect(4)];
            DividerRect1(DividerRect1 <= 0) = 1; % Ensure boundsvb
            DividerRect1(DividerRect1 >= Parameters.StimRect(3)) = Parameters.StimRect(3); % Ensure bounds
            Screen('FillRect', CircAperture, Parameters.Background, DividerRect1);
        end

        % Draw movie frame
        Screen('DrawTexture', Win, BgdTextures(CurrStim), Parameters.StimRect, CenterRect(FrameRect, Rect), CurrCondit-90); % removed BgdAngle here, not needed!
        % Draw aperture 
        Screen('DrawTexture', Win, CircAperture, Parameters.StimRect, CenterRect(FrameRect, Rect), CurrCondit-90);
        
        % Are we changing the color of the fixation dot?
        CurrEvents = (GetSecs - StartofExperiment) - Behavior.EventTime;
        
        
        % Draw fixation dot 
        if sum(CurrEvents > 0 & CurrEvents < Parameters.Event_Duration)
            % This is an event
            Screen('FillOval', Win, Parameters.Event_Colour(1,:), CenterRect([0 0 Parameters.Fixation_Width(1) Parameters.Fixation_Width(1)], Rect));
            % disp('Doosi!')
        else
            % This is not an event
            Screen('FillOval', Win, Parameters.Event_Colour(2,:), CenterRect([0 0 Parameters.Fixation_Width(1) Parameters.Fixation_Width(1)], Rect));    
        end

        % Flip screen and get actual timestamp
        vbl = Screen('Flip', Win, vbl + 0.5 * ifi); % Sync to VBL

        % If saving movie
        if SaveAps == 1 && PrevVolume ~= CurrVolume
            Screen('FillOval', Win, Parameters.Background, CenterRect([0 0 Parameters.Fixation_Width(1) Parameters.Fixation_Width(1)], Rect));
            Screen('Flip', Win);
            PrevVolume = CurrVolume;
            CurApImg = Screen('GetImage', Win, [], 'backbuffer');     
            CurApImg = rgb2gray(CurApImg);
            CurApImg = double(abs(double(CurApImg)-127)>1);
            Fxy = round(CenterRect(FrameRect, Rect));
            Fxy(Fxy <= 0) = 1;
            if Fxy(3) > Rect(3)
                Fxy(3) = Rect(3);
            end
            if Fxy(4) > Rect(4)
                Fxy(4) = Rect(4);
            end
            % DR: subtracting 1 from end coordinates to correctly crop the image to size of FrameRect. 
            % The original code had one extra pixel in each dim 
            CurApImg = CurApImg(Fxy(2):Fxy(4)-1, Fxy(1):Fxy(3)-1); 
            CurApImg = round(imresize(CurApImg, [100 100], 'nearest')); % nearest neighbor creates holes, but more accurate bars
            ApFrm(:,:,ApFrmIdx(Trial)+CurrVolume) = imfill(CurApImg, 'holes'); % fill the holes ;
            
        end

        % Store flip time
        % flipTimes(CurrFrame) = vbl;
        flipTimesRun(idx_vbl) = vbl;
        idx_vbl = idx_vbl + 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [keyIsDown, keyTime, keyCode] = KbCheck;
        % Exit if escape is pressed
        if keyIsDown && keyCode(KeyCodes.Escape)
                disp('Escape key pressed. Exiting...');
                sca;
            return;
         end

        if parallelPort
            % If using parallel port
            [inputIsDown, inputTime, inputCode] = ParallelCheck;
            if inputIsDown 
                if inputCode.Trigger && ~triggerPressed %&& inputTime - StartofTrial > 1 % the last part is a quick fix to the problem that we ALWAYS get triggers at the beginning of the Trial, even if there was no trigger
                    % Save the time of the trigger
                    Trigger.Time = [Trigger.Time; inputTime - StartofExperiment];
                    Trigger.Number = Trigger.Number + 1; % before or after disp ...?
                    if length(Trigger.Time)>=2
                        disp(['Trigger No. ' n2s(Trigger.Number) ' received after ' n2s(Trigger.Time(end)-Trigger.Time(end-1))]);
                    end
                    triggerPressed = true;
                elseif inputCode.Response && ~buttonPressed
                    disp(['Response captured at ' num2str(inputTime - StartofExperiment)]);
                    Behavior.ResponseTime = [Behavior.ResponseTime; inputTime - StartofExperiment];
                    buttonPressed = true;
                end
            else
                buttonPressed = false;
                triggerPressed = false;
            end
            WaitSecs(0.0001); % 0.1ms to avoid CPU overload!!!
            
        else
            % If using keyboard setup at scanner us this 
            % Check key presses 
            if keyIsDown
                if keyCode(KeyCodes.Trigger) && ~triggerPressed
                    % Save the time of the trigger
                    Trigger.Time = [Trigger.Time; keyTime - StartofExperiment];
                    Trigger.Number = Trigger.Number + 1;
                    if length(Trigger.Time)>=2
                        disp(['Trigger No. ' n2s(Trigger.Number) ' received at ' n2s(Trigger.Time(end)-Trigger.Time(end-1))]);
                    end
                    triggerPressed = true;
                elseif keyCode(KeyCodes.Response) && ~buttonPressed
                    disp(['Recorded Response: ' n2s(KeyCodes.Response)]);
                    Behavior.ResponseTime = [Behavior.ResponseTime; keyTime - StartofExperiment];
                    buttonPressed = true;
                end
            else
                buttonPressed = false;
                triggerPressed = false;
            end
        end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  


        if mod(CurrFrame, framesPerVolume) == 0 && CurrVolume < Parameters.VolsPerTrial(Trial)
            CurrVolume = CurrFrame / framesPerVolume +1;
        end

        % Are there timing issues?
        %  if CurrVolume is on for longer than a 4.206 seconds, then move to next volume
        if GetSecs - StartofTrial > Parameters.VolumeTR * CurrVolume + 0.0001
            % move to next volume
            elapsedTime = GetSecs - StartofTrial;
            correctedVols = correctedVols + 1;
            if CurrVolume ~= Parameters.VolsPerTrial(Trial)
                warning(['Volume ' n2s(CurrVolume) ' took too long (' n2s(elapsedTime/CurrVolume) '), moving on to next volume']);
                CurrVolume = CurrVolume + 1;
            else
                disp(['Volume ' n2s(CurrVolume) ' took too long (' n2s(elapsedTime/CurrVolume) '), moving on to next trial']);
                break
            end
        end

        CurrFrame = CurrFrame + 1; % DO NOT EVER THINK OF SKIPPING FRAMES HERE!

        
    end

    % Trial completed
    elapsedTime = GetSecs - StartofTrial;
    fprintf('Trial %d completed in %.3f seconds\n', Trial, elapsedTime);

end
% Get the measured ExperimentLength and compare it with what you expected
ExperimentLength = GetSecs - StartofExperiment; % Time experiment length
ExperimentLengthDifms = 1000 * abs((ExperimentLength - Parameters.ExptDuration));
if ExperimentLength > Parameters.ExptDuration
    fprintf('The experiment was %.0f ms longer than the expected duration.\n', ExperimentLengthDifms)
else
    fprintf('The experiment was %.0f ms shorter than the expected duration.\n', ExperimentLengthDifms)
end
Trigger.RelTime = diff(Trigger.Time);

% Save everything and close
Parameters.SaveFile = sprintf('%d_subj%d_ses%d_%s_run0%d_%dbr_%dTR_%dHz', Parameters.Date, Parameters.SubjNum, Parameters.SesNum, Parameters.Sequence, Parameters.RunNum, Parameters.NumBars, Parameters.TRperSweep, round(Parameters.FlickerFreq));
% downsampling option removed from name, because it is not used anymore
save(['Results' filesep Parameters.SaveFile]);

% Close screen
sca;


%% How well did you do?
addpath('~/Documents/odc_bssfp/analysis/');
BehaviorAnalysis(['Results' filesep Parameters.SaveFile], 2);

