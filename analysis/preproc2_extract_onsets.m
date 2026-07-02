% Extract tap onset times from the continous data. This can be done in two
% ways. 


%% Option 1: GUI 

% Change folder to "onset_extraction_GUi" and run function
% "onset_extraction_GUI.m". Make sure to update the paths and parameters
% at the start of the function. 

%% Option 2: semi-automatic without GUI

clear 

% The function `extract_taps` is in the ftrsa package. Make sure you have
% the package on your machine (download it from
% https://github.com/TomasLenc/ftrsa), and update the path below to point
% to the folder where you've downloaded it.
addpath(genpath('/Users/tomaslenc/projects_git/ftrsa/src')); 

% load continuous tapping data 
data = load('data/tap_data_aligned.mat'); 

% set extraction parameters
tap_onset_amp_thr = 0.05; 
tap_onset_min_iti = 0.080; 

tap_onset_times = extract_taps(abs(data.data), ...
                               data.fs, ...
                               tap_onset_amp_thr, ...
                               tap_onset_min_iti, ...
                               'plot_diagnostic', true); 


