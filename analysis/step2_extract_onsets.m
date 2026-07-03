% Extract tap onset times from the continous data. This can be done in two
% ways. 


%% Option 1: GUI 

% Change folder to "onset_extraction_GUi" and run function
% "onset_extraction_GUI.m". Make sure to update the paths and parameters
% at the start of the function. 

%% Option 2: semi-automatic without GUI

clear 

% load continuous tapping data 
data = load('data/tap_data_aligned.mat'); 

% set extraction parameters
tap_onset_amp_thr = 0.05; 
tap_onset_min_iti = 0.080; 

% take the absolute value of the continuous signanl 
x = abs(data.data); 

% detect tap onsets
tap_indices = find(x > tap_onset_amp_thr) ; 
asy = [Inf, diff(tap_indices) / data.fs]; 
tap_indices(asy < tap_onset_min_iti) = []; 
tap_onset_times = tap_indices / data.fs; 

% plot
figure('color', 'w', 'pos', [-415 1596 2517 682]); 
t = [0:length(x)-1]/data.fs; 
plot(t, x); 
hold on 
plot(t(tap_indices), tap_onset_amp_thr, 'ro')   
plot([0, t(end)], [tap_onset_amp_thr, tap_onset_amp_thr], 'k:', 'linew', 2)


