clear


% load stimulus audio and parameters
stim = load('data/stim.mat'); 

% get original stimulus audio used for playback 
s = stim.s; 

% load tapping 
[tap_data, fs] = audioread('data/tap_data.wav'); 

% get the stimulus recorded from the audio interface
s_rec = tap_data(:, 2)'; 

% normalize amplitude 
s_rec = s_rec ./ max(abs(s_rec)); 

% we should have the same sampling rate but just to be sure 
if fs ~= stim.fs
    s = resample(s, fs, stim.fs);        
end

%% estimate delay in the recorded data (usually it's 3-5 ms) 

% cross-correlate the original and recorded audio 
[xc, lags] = xcorr(s_rec, s); 

% get the lag with maximal corrleation 
[~, idx] = max(xc); 
rec_delay_N = lags(idx); 

% align the recording so it starts exactly at the same time as the stimulus
% audio file 
N = round(stim.trial_dur * fs); 
tap_data_aligned = tap_data(rec_delay_N : rec_delay_N+N-1, :); 

%% plot

figure 

% plot the original audio
plot(s ./ max(abs(s)))

hold on 

% plot the recorded and aligned audio
plot(tap_data_aligned(:,2)  ./ max(abs(s_rec)))

% The two should overlap almost perfectly! 


%%

% save the aligned continuous tapping data
data = tap_data_aligned(:,1)'; 

save('data/tap_data_aligned.mat', 'data', 'fs')




