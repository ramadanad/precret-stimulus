function test_screen_range(Parameters)



StimRect = [0 0 repmat(size(Parameters.Stimulus,1), 1, 2)];

% Go to folder of calling wrapper function
GoToCurrFunc; 

%% Initialize randomness & keycodes
SetupRand; %DR: checked
SetupKeyCodes; %DR: added Trigger


%% Initialize PTB
if ~isfield(Parameters, 'Gamma')
    Parameters.Gamma = 1; % If gamma undefined, don't use
end
%Screen('Preference', 'SkipSyncTests', 1);
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma');
[Win, Rect] = PsychImaging('OpenWindow', Parameters.Screen, Parameters.Background, Parameters.Resolution, 32);%, [], 32); %Parameters.Resolution, 32); No need to specify the 32 bits per pixel... it is the default!


%% FrameRect

FrameRect = [0 0 repmat(StimRect(4), 1, 2)]; %DR: changed that from Rect(4) to StimRect(4)

%% Test circular aperture

% Draw red ring (unfilled oval with line width)
lineWidth = 5; % Thickness of the ring outline
Screen('FillOval', Win, Parameters.RED, CenterRect(FrameRect, Rect));%, lineWidth); % use linewidth if you use the FrameOval command
% Draw fixation dot
Screen('FillOval', Win, Parameters.Event_Colour(2,:), CenterRect([0 0 Parameters.Fixation_Width(1) Parameters.Fixation_Width(1)], Rect));

DrawFormattedText(Win, 'Hello, thanks for being here! \n \n \nPlease make sure that \n \na) you can see the entire circle and \nb) the blue fixation dot is clearly visible. \n \n \nIf not, please press the ball and let me know :) \n \n', 1920/2-150, 1080/2+0.1*1080, Parameters.Foreground); 
Screen('TextSize', Win, 110);
DrawFormattedText(Win, 'L',0.1*1920, 0.5*1080, Parameters.Foreground); 
DrawFormattedText(Win, 'R',0.9*1920, 0.5*1080, Parameters.Foreground);
DrawFormattedText(Win, 'T',0.5*1920, 0.15*1080, Parameters.Foreground); 
DrawFormattedText(Win, 'B',0.5*1920, 0.9*1080, Parameters.Foreground); 

% Flip to screen
Screen('Flip', Win);

% Wait for Escape key
% Define ESC key code
ESC_KEY = KbName('ESCAPE');

% Instruction
disp('Press ESC to quit...');

% Wait for ESC key
while true
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown
        if keyCode(ESC_KEY)
            break; % ESC pressed, exit loop
        end
    end
end


% Close screen
sca;
