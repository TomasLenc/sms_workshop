% Extract tap onset times from the continous data. 
clear 

% the function `extract_taps` is in the ftrsa package (get it from
% https://github.com/TomasLenc/ftrsa)
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


