% Set up the randomizers for uniform and normal distributions. 
% It is of great importance to do this before anything else!

% try
%     % Use the recommended method in Matlab R2012a.
%     rng('shuffle');
%     disp('Using modern randomizer...');
% catch
%     % Use worse methods for old versions of Matlab (e.g. 7.1.0.246 (R14) SP3).
%     try
%         rand('twister',sum(100*clock));
%         randn('state',sum(100*clock));
%         disp('Using outdated randomizer...');
%     catch
%         % For very old Matlab versions these are the only methods you can use.
%         % These are supposed to be flawed although you will probably not
%         % notice any effect of this for most situations.
%         rand('state',sum(100*clock));
%         randn('state',sum(100*clock));
%         disp('Using "flawed" randomizer...');
%     end
% end



%DR: trying out new things, cause it used to always use flawed randomizer:
try
    % Use the recommended method for modern MATLAB versions.
    rng('shuffle');
    disp('Using modern randomizer...');
catch ME
    % If an error occurs, ensure the generator is reset to default and retry.
    warning('An error occurred: %s\nResetting to default generator...', ME.message);
    rng('default'); % Reset to modern default generator
    rng('shuffle'); % Reapply shuffle for randomization
    disp('Using modern randomizer after reset...');
end