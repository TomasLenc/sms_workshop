%% Simple Audio Playback and Recording Example
%
% This script demonstrates how to:
%   1. Create a simple metronome-like stimulus from a short sound sample.
%   2. Using Psychtoolbox audio functions: (i) Play the stimulus, and (ii)
%      simultaneously record audio input (e.g., participant taps). 
%   3. Visualize the recorded signals. 
%   4. Save the generated stimulus and recorded data for later analysis.
%
% The example is intended as a minimal template for sensorimotor
% synchronization experiments and tapping tasks.

clear all
clc

%% Stimulus generation

% Load a short sound event (e.g., a hi-hat sound)
[s_event, fs] = audioread('hihat.wav');

% Inter-onset interval (IOI) in seconds.
% This determines the time between successive sound events.
ioi = 0.5;

% Total duration of the trial in seconds
trial_dur = 30;

% Calculate the total number of sound events in the sequence
n_events = trial_dur / ioi;

% Create onset times (in seconds) for all sound events
t_onsets = [0 : n_events-1] * ioi;

% Convert onset times from seconds to audio sample indices
idx_onsets = round(t_onsets * fs);

% Create an empty audio signal covering the entire trial duration
N = round(trial_dur * fs);
s = zeros(1, N);

% Insert the sound event at every scheduled onset location
for i_event = 1:n_events
    s(idx_onsets(i_event)+1 : idx_onsets(i_event)+length(s_event)) = s_event;
end

% Create a time vector for the complete stimulus
t = [0 : N-1] / fs;

% Save the stimulus and timing information for later analysis
save('stim.mat', 'ioi', 'trial_dur', 'n_events', 't_onsets', 's', 'fs');


%% Initialize Psychtoolbox (PTB)

% Initialize the random number generator using the current time
seed = sum(clock * 100);
RandStream.setGlobalStream(RandStream('mt19937ar', 'seed', seed));

% Perform dummy calls so that these functions are already loaded
% before the experiment starts. This helps avoid timing delays
% caused by first-time function initialization.
WaitSecs(0.1);
GetSecs;


%% Open audio devices

% Initialize PsychPortAudio.
% The argument '1' requests low-latency operation.
InitializePsychSound(1);

% Retrieve a list of all available audio devices
dev = PsychPortAudio('GetDevices');


%% Configure audio output

% Find the desired playback device. Here I'm searching for the MOTU
% UltraLite-mk5 audio interface connected via USB.  
idx_out = strcmp({dev.DeviceName}, 'UltraLite-mk5');

assert(sum(idx_out) == 1, ...
    'I have trouble finding ultralite output device...');

% Store the device index
dev_index_out = dev(idx_out).DeviceIndex;

% Number of playback channels (stereo)
n_chan_out = 2;

% Open the playback device
pahandle_out = PsychPortAudio('Open', ...
                            dev_index_out, ...  % device index
                            1, ...            % mode: playback
                            3, ...            % latency class
                            fs, ...           % sampling rate
                            n_chan_out);      % number of channels


%% Configure audio input

% Find the desired recording device.
%
% On macOS, a multichannel audio interface typically appears as a single
% audio device, with all input and output channels accessible through
% PsychPortAudio. This makes channel selection relatively straightforward.
%
% On Windows, audio device enumeration depends on the driver architecture
% and hardware configuration. Some interfaces appear as a single
% multichannel device, whereas others expose separate channel groups
% (e.g., Input 1&2, Input 3&4, Output 1&2, etc.) as independent devices.
% Consequently, it is often necessary to inspect the device list and
% identify which device corresponds to the desired channel pair.
%
% Older Psychtoolbox setups could optionally use ASIO drivers for direct
% access to professional audio hardware. However, ASIO support is no
% longer distributed with Psychtoolbox because of licensing constraints.
% Modern PTB versions on Windows primarily use WASAPI (and, in some cases,
% WDM/KS) for low-latency audio operation. See the documentation for
% InitializePsychSound for additional background.
%
% In practice, the main task is simply to find the device corresponding to
% the input channels carrying:
%   (1) the tapping-box signal, and
%   (2) the stimulus loopback signal.
%
% Inspect the variable 'dev' to view all available devices if you are
% unsure which one to select.
idx_in = strcmp({dev.DeviceName}, 'UltraLite-mk5');

assert(sum(idx_out) == 1, ...
    'I have trouble finding ultralite input device...');

% Store the device index
dev_index_in = dev(idx_in).DeviceIndex;

% Number of recording channels
n_chan_in = 2;

% Open the recording device
pahandle_in = PsychPortAudio('Open', ...
                                    dev_index_in, ...
                                    2, ...      % mode: capture
                                    3, ...      % latency class
                                    fs, ...
                                    n_chan_in);


%% Audio setup

% Set playback volume.
% Be careful with volume settings when using headphones.
PsychPortAudio('Volume', pahandle_out, 0.1);

% Allocate enough recording buffer space for the entire trial
PsychPortAudio('GetAudioData', pahandle_in, trial_dur * 2);

% Play one second of silence to warm up audio drivers and reduce
% the likelihood of timing irregularities at stimulus onset.
s_out = zeros(n_chan_out, round(fs * 1));
PsychPortAudio('FillBuffer', pahandle_out, s_out);
PsychPortAudio('Start', pahandle_out, 1, [], 1);
PsychPortAudio('Stop', pahandle_out, 1);


%% Playback and recording

% Create a stereo version of the stimulus
s_out = repmat(s, n_chan_out, 1);

% Load the stimulus into the playback buffer
PsychPortAudio('FillBuffer', pahandle_out, s_out);

% Start recording.
%
% Arguments:
%   handle
%   repetitions
%   start time (empty = immediately)
%   waitForStart
PsychPortAudio('Start', pahandle_in, 1, [], 1);

% Start playback and store the actual onset timestamp
%
% Arguments:
%   handle
%   repetitions
%   when (empty = immediate)
%   waitForStart
start_time = PsychPortAudio('Start', pahandle_out, 1, [], 1);

% Wait until playback is finished, then stop playback
PsychPortAudio('Stop', pahandle_out, 1);

% Stop audio recording
PsychPortAudio('Stop', pahandle_in, 1);

% Retrieve all recorded audio samples from the capture buffer
tap_data = PsychPortAudio('GetAudioData', pahandle_in);


%% Visualize recorded signals

% Create a time vector for the recorded audio
t = [0 : size(tap_data,2)-1] / fs;

figure

subplot(2,1,1)
plot(t, tap_data(1,:), 'linew', 1.5);
title('Tapping signal');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(2,1,2)
plot(t, tap_data(2,:), 'linew', 1.5);
title('Captured stimulus');
xlabel('Time (s)');
ylabel('Amplitude');


%% Save recorded audio

% Save the recorded channels as a WAV file
audiowrite('tap_data.wav', tap_data', fs);


%% Cleanup

% Close all audio devices opened by PsychPortAudio
PsychPortAudio('Close');

% Close all Psychtoolbox screens and windows
sca;

% Return MATLAB to normal priority scheduling
Priority(0);