function GoToCurrFunc
% Changes working directory to the path of the current function

X = dbstack('-completenames');
disp(['Navigating to: ' fileparts(X(end).file)]);
cd(fileparts(X(end).file));
