% This is a minimal script 

clear all
clc


%% Stimuli

% sound event 
[s_event, fs] = audioread('hihat.wav'); 

% inter-onset interval 
ioi = 0.5; 

% total trial duration 
trial_dur = 30; 

% get the total number of sound events in the sequence
n_events = trial_dur / ioi; 

% prepare sound onsest sample indices for each of the N sounds in
% this pattern cycle           
t_onsets = [0 : n_events-1] * ioi; 

% compute sample index of each event onset 
idx_onsets = round(t_onsets * fs); 

% create continuous audio sequence (no sounds yet)
N = round(trial_dur * fs); 
s = zeros(1, N);        

% insert the sounds to the long sequence 
for i_event=1:n_events
    s(idx_onsets(i_event)+1 : idx_onsets(i_event)+length(s_event)) = s_event; 
end

% create a time vector
t = [0 : N-1] / fs; 

% save the stimulus as mat file (we will need it for analysis later)
save('stim.mat', 'ioi', 'trial_dur', 'n_events', 't_onsets', 's', 'fs'); 

%% initialize PTB

% setup random number generator
seed = sum(clock * 100); 
RandStream.setGlobalStream(RandStream('mt19937ar', 'seed', seed));

% Do dummy calls to GetSecs, WaitSecs, KbCheck to make sure
% they are loaded and ready when we need them - without delays
% in the wrong moment:
WaitSecs(0.1);
GetSecs;


%% Open Audio

% read the docs !
InitializePsychSound(1); % flag reallyneedlowlatency

% get audio device list
dev = PsychPortAudio('GetDevices');

%------ output ------

idx_out = strcmp({dev.DeviceName}, 'UltraLite-mk5'); 

assert(sum(idx_out) == 1, ...
    'I have trouble finding ultralite output device...'); 

dev_idx_out = dev(idx_out).DeviceIndex; 

n_chan_out = 2; 

pahandle_out = PsychPortAudio('Open', ...
                            dev_idx_out, ... % deviceid
                            1, ... % mode (1: playback, 2: capture) 
                            3, ... % reqlatencyclass 
                            fs, ... %sampling rate
                            n_chan_out); %number of output channels
                        
%------ intput ------

idx_in = strcmp({dev.DeviceName}, 'UltraLite-mk5'); 

assert(sum(idx_out) == 1, ...
    'I have trouble finding ultralite input device...'); 

dev_idx_in = dev(idx_in).DeviceIndex; 

n_chan_in = 2; 

pahandle_in = PsychPortAudio('Open', ...
                                    dev_idx_in, ...
                                    2, ...
                                    3, ...
                                    fs, ...
                                    n_chan_in);
  
%% Set up audio
                               
% set initial PTB volume (careful with this!)
PsychPortAudio('Volume', pahandle_out, 0.1);

% if we're doing capture, we need to initialize buffer with enough space
PsychPortAudio('GetAudioData', pahandle_in, trial_dur * 2); 

% play a bunch of zeroes (1-s silence) to warm up the audio drivers
s_out = zeros(n_chan_out, round(fs * 1)); 
PsychPortAudio('FillBuffer', pahandle_out, s_out); 
PsychPortAudio('Start', pahandle_out, 1, [], 1);  
PsychPortAudio('Stop', pahandle_out, 1);                         

%% playback 

% prepare stereo output
s_out = repmat(s, n_chan_out, 1); 

% fill buffer     
PsychPortAudio('FillBuffer', pahandle_out, s_out); 

% START CAPTURE
% pahandle, repetitions, when, waitForStart
PsychPortAudio('Start', pahandle_in, 1, [], 1);  

% START PLAYBACK
% handle, repetitions, when=0, waitForStart
start_time = PsychPortAudio('Start', pahandle_out, 1, [], 1);  

% STOP CAPTURE and PLAYBACK  
% pahandle [, waitForEndOfPlayback=0] [, blockUntilStopped=1]
PsychPortAudio('Stop', pahandle_out, 1);                         
PsychPortAudio('Stop', pahandle_in, 1);                         

% extract recorded audio from the buffer
tap_data = PsychPortAudio('GetAudioData', pahandle_in); 

%%
  
t = [0 : size(tap_data,2)-1] / fs; 

figure
subplot 211
plot(t, tap_data(1,:), 'linew', 1.5); 
title('tapping')

subplot 212
plot(t, tap_data(2,:), 'linew', 1.5); 
title('stimulus (captured)')


%%

audiowrite('tap_data.wav', tap_data', fs); 


%%

% close all audio devices
PsychPortAudio('Close');

% Screen Close All
sca;

% release priority
Priority(0);
