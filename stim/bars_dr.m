function bars_dr(Subject, Session, Sequence, Run, Testing)
% This function highly relies on Samsrf's function Bars.m found in the
% StimulusCode here: https://osf.io/9tqjn/ 
% However, there are some changes to the map_bars function that are
% explained there, especially w.r.t. timing

% This function calls the map_bars function. The Parameters set here are
% used as inputs to the map_bars function.
%
%   Inputs:
%       Subject     -   Subject number, e.g. 2
%       Session     -   Session number, e.g. 2
%       Sequence    -   Sequence type, either 'bssfp' or 'epi'. 
%                       OR you can also use 'ApFrm' as sequence!!!
%                       In this case it will save the aperture. 
%                       Saving the aperture ruins the timing!            
%       Run         -   Run number, e.g. 1
%       Testing     -   If you want to test the function, set this to 1
%                       Otherwise set it to 0

%
% Some explanations:
% A "sweep" is when a bar is sweeping through the visual field
% A "rest" is when no bar is shown
% A "trial" is either a sweep or rest 
% A "volume" is how long a bar stays in one position and also refers to the
% fMRI volume TR

%% How to start
% To test the experiment on your PC, press q to start the experiment, and 4
% to react to a color change.

% At the 9.4 T in Tuebingen we usually use parallel port, because then we
% don't have timing issues when trigger and reaction to a color change are
% at the same time.
% To start the experiment, a trigger should arrive. This is a q or a
% parallel port input. This depends on whether TriggerExperimentPP
% (parallel port) or TriggerExperimentKB (keyboard) is active.


%% Who are you measuring? Or are you just testing?
% These parameters are used for saving the file correctly
if Testing == 1
    Parameters.Conditions = [0 45];
    Parameters.Dummies = 1; % Number of dummy volumes
    Parameters.SubjNum = 0;
    Parameters.SesNum = 0;
else
    Parameters.Dummies = 3; % Number of dummy volumes
    Parameters.Conditions = [NaN 0 45 90 135 NaN 180 225 270 315 NaN]; 
    Parameters.SubjNum = Subject;
    Parameters.SesNum = Session;
end
Parameters.Sequence = Sequence; % Sequence type, either 'bssfp' or 'epi'
Parameters.RunNum = Run; % Run number
Parameters.Date = str2double(datestr(now, 'yymmdd'));
%% Set the colors
Parameters.Background = [127 127 127]; % Background color
Parameters.RED = [255 0 0]; % Red color, just qfor testing
Parameters.Foreground = [0 0 0];  % Foreground colour


%% Change these if you want!
% Stimulus specific parameters
Parameters.Refreshs_per_Stim = 6; % Number of refreshes per stimulus, flickering frequency = screen refresh rate / (2 * refreshs per stim)
% If you want 5 Hz, set this to 6 at a 60 Hz screen or 12 at a 120 Hz
% screen
Parameters.NumBars = 1; % Use 1 or 2 bars. Function not made for more!
if ~(Parameters.NumBars == 1 || Parameters.NumBars == 2)
    error('Parameters.NumBars must be either 1 or 2.');
end    
Parameters.TRperSweep = floor(18/Parameters.NumBars); % Set this to double the actual TR per sweep for a 2 bar design
Parameters.TRperRest = 8; % This ishow many TRs you wait in the rest period (usually in the beginning, middle and end of run)
%       SaveAps     -   Do you want to save the aperture for later use in
%       the modeling of the pRFs? You should only set this to 1 OUTSIDE of
%       your normal experiment. If this is one, it causes weird
%       (intentional) flips and also critical timing issues. Always set to
%       0 if your running the real experiment
if strcmp(Sequence, 'bssfp')
    Parameters.VolumeTR = 4.206; % Actual volume TR (Ic know it's long :/)
    SaveAps = 0;
elseif strcmp(Sequence, 'epi')
    Parameters.VolumeTR = 4.2;
    SaveAps = 0;
elseif strcmp(Sequence, 'ApFrm')
    Parameters.VolumeTR = 1;
    SaveAps = 1;
else 
    error('Sequence must be either bssfp or epi.');
end

Parameters.VolsPerSweep = Parameters.TRperSweep; 
Parameters.VolsPerTrial = zeros(size(Parameters.Conditions));
Parameters.VolsPerTrial(isnan(Parameters.Conditions)) = Parameters.TRperRest;
Parameters.VolsPerTrial(~isnan(Parameters.Conditions)) = Parameters.TRperSweep;

%% Stimulus
Stim = 'Checkerboard_noecc_1000.mat';
% Load stimulus movie
load(Stim, "Stimulus"); 
Parameters.Stimulus = Stimulus; % Stimulus movie
StimRect = [0 0 repmat(size(Parameters.Stimulus,1), 1, 2)];
Drift_per_Vol = StimRect(3) / Parameters.VolsPerSweep / Parameters.NumBars;
Parameters.BarPos = round(Drift_per_Vol/2 : Drift_per_Vol : StimRect(3)-Drift_per_Vol/2); % DR: round BarPos to make sure bar width is always constant
Parameters.StimRect = StimRect;
Parameters.Bar_Width = floor(Drift_per_Vol*2 / 10) * 10; % Better for getting more accurate ApFrm, because I am using 1000x1000 pixel
% Parameters.Bar_Width ensures a ~50% overlap between one bar and the next
%% Color change and button press
Parameters.Event_Duration = 0.2; % Duration of color change 
Parameters.Prob_of_Event = 0.01; % Probability of event
Parameters.Fixation_Width = [10 0]; % Width of the fixation point
Parameters.Event_Colour = [127 0 255; 0 0 255]; %DR: violet, blue

%% Screen
Parameters.Screen = max(Screen('Screens'));% 0 for testing at scanner, otherwise max
Parameters.Resolution = [0 0 1920 1080];
Parameters.FontName = 'Arial';  % Font to use
Parameters.FontSize = 30;   % Size of fontq
Parameters.Welcome = 'Please fixate the blue dot at all times!';   % Welcome message
Parameters.Instruction = 'Please press a button when it changes colour!';  % Instruction message

%% Now do the mapping!
% test_screen_range(Parameters); % use this code at the beginning of each experiment to test if participant can see everything!
map_bars(Parameters, SaveAps); % That is the actual bars mapping paradigm.
% 