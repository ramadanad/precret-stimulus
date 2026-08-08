function parallelPort = checkParportExistence()
%CHECKPARPORTEXISTENCE checks if the function parport exists
% No input! It just checks if the function parport written by Joachim exists on
% the stimulus computer.

% Output is a boolean, it either exists (true) or it doesn't (false)

if exist('parport', 'file')
    disp('The parport function exists, so I am using the parallel port to check for triggers and button presses.');
    parallelPort = true;
else
    warning('No parallel port found! Checking for keypresses.');
    parallelPort = false;
end

