clear

myblue = [66, 135, 245]/255;
myred = [209, 70, 48]/255;

% For efficiency, we'll use some functions from the rnb_tools package.
% Download it from:
%
%   https://github.com/TomasLenc/rnb_tools
%
% and update the path below to point to your local installation.
addpath(genpath('/Users/tomaslenc/projects_git/rnb_tools/src'));

% Add local helper functions (simulation and model-fitting code).
addpath(genpath('../lib'));

%% Load stimulus and tap onset times

% At this stage we have already:
%
%   (1) generated the metronome stimulus,
%   (2) aligned the recorded audio with the original stimulus timeline,
%   (3) extracted individual tap onset times.
%
% The goal of this script is to move from signal processing to behavioral
% analysis. We will quantify how accurately and consistently the
% participant synchronized their taps with the metronome.

% Load stimulus parameters
stim_times = load('data/stim.mat');
stim_ioi = stim_times.ioi;

% Load extracted tap onset times (one trial)
tbl = readtable('data/tap_onsets.csv');
tap_times = tbl.onset;

%% Visualize the tapping sequence

% As a first sanity check, plot the stimulus waveform together with the
% detected tap times.
%
% Always inspect the raw data before calculating summary statistics.
% Problems such as missed taps, double taps, or onset-detection errors are
% often obvious in a simple visualization.

figure('color', 'white');

t = [0 : length(stim_times.s)-1] / stim_times.fs;

plot(t, stim_times.s, ...
     'color', [.8, .8, .8], ...
     'linew', 1)

hold on

plot(tap_times, ...
     0, ...
     'o', ...
     'MarkerFaceColor', myblue, ...
     'MarkerEdgeColor', 'none')

box off

ax = gca;
ax.FontSize = 18;

%% Inter-tap intervals (ITIs)

% The inter-tap interval (ITI) is the time between two consecutive taps:
%
%       ITI(n) = tap(n) - tap(n-1)
%
% If a participant successfully synchronizes to the metronome, ITIs should
% cluster around the stimulus inter-onset interval (IOI). HOWEVER, don't
% forget that ITIs have low specificity to measure synchornization - as
% explained in the lecture, we can have cases with mean ITI very close to
% the target metronome IOI, and still the two can be desynchronized in the
% absence of error correction (AKA "coupling" in dynamical systems
% terminology).

% Calculate inter-tap intervals
itis = diff(tap_times);

% Plot the ITI distribution and compare it with the target IOI
f = figure('color','white','position',[146 581 229 164]);

h = histogram(itis, ...
    'binedges', [stim_ioi*0.55 : 0.02 : stim_ioi*1.55]);

hold on

% Dashed line = target metronome period
plot([stim_ioi, stim_ioi], ...
     [0, max(h.Values) * 1.2], ...
     '--', ...
     'color', myred, ...
     'linew', 2)

h.FaceColor = myblue;
h.EdgeAlpha = 0.3;

ax = gca;
ax.YTick = [];
ax.XTick = stim_ioi;
ax.XTickLabel = {};
ax.XLim = [stim_ioi * 0.55, stim_ioi * 1.55];
ax.YLim = [0, max(h.Values) * 1.2];
ax.TickDir = 'out';

box off

% Long pauses, missed taps, or accidental double taps can produce extreme
% ITIs. Check the distribution and remove huge outliers manually. 

% Median is often a more robust summary statistic
Such outliers can strongly influence the mean, which is why the
mean(itis)
median(itis)

%% Measure synchronization 

% Measuring Stimulus-Tap Asynchronies allows us to answer two questions: 
%   (1) "At what point within the metronome cycle do taps occur?"
%   and 
%   (2) "How consistenly do they occur there?"
% 
% As explained in the lecture the latter question is KEY to measure
% synchronization, as defined in physics. 
%
% But rather than computing asynchronies explicitly (by first assigning
% each tap to the closest metronome click and then computing the time
% difference between the two), we can take advantage of a circular (polar)
% representation. 

% Fold all taps into a single metronome cycle (expressing WHERE each tap
% occurs between two successive metronome clicks)
phase_in_sec = mod(tap_times, stim_ioi);

% Convert phase to radians
phase_in_rad = phase_in_sec / stim_ioi * 2*pi;

% Compute resultant vector length:
% r = 0 -> no phase consistency (weak synchronization)
% r = 1 -> perfect phase consistency (strong synchronization)
r = abs(mean(exp(1j*phase_in_rad)));

% Compute mean phase angle
theta = angle(mean(exp(1j*phase_in_rad)));

% plot
f = figure('color','white','position',[146 581 229 164]);
ax = polaraxes;

h = polarplot(phase_in_rad, ...
    ones(length(phase_in_rad),1), ...
    'o', ...
    'color', myblue, ...
    'linew', 1.5);

h.MarkerSize = 10;

hold on

% Mean phase vector
polarplot([theta,theta], [0;r], ...
    'color', myred, ...
    'linew', 3);

set(ax,...
    'thetaAxisUnits','radians',...
    'thetatick',[0,pi/2,pi,3*pi/2],...
    'thetaticklabel',{'0','ioi/4','ioi/2','-ioi/4'},...
    'rtick',[],...
    'rlim',[0,1.1],...
    'FontSize',16,...
    'GridAlpha',1);

%% Simulate tapping

% Above, we've analyzed real data recorded from an actual tapping. But it
% is also super useful to generate synthetic data and play around to
% understand how the measures work. 
%
% The simulation below implements a simple generative error-correction
% model that tries to minimize stimulus-tap asynchronies (errors).
%
% By changing model parameters we can explore how phase correction,
% period correction, and noise affect synchronization measures.

% stimulus (metronome) inter-onset interval 
stim_ioi = 0.5;

% total duration of the metronome sequence 
trial_dur = 30;

% compute metronome click times
stim_times = [0 : 0.5 : trial_dur]';

% simulate tapping (see docstring for info about the parameters)
tap_times = simulate_tapping( ...
                stim_times, ...
                'alpha', 0.5, ... % phase correction 
                'beta', 0.0, ... % period correction 
                'Tvar', 0.01, ... % timekeeper variance (noise)
                'Tinit', 0.50); % initial timekeeper period

% As an exercise, try playing around with the parameters: 
% 
% (1) What happens if you set Tinit a tiny bit above stim_ioi and set all
% error correction (alpha and beta) to 0?
% 
% (2) What happens if you set Tinit tiny bit above stim_ioi and add phase
% correction (alpha > 0)? Can the system achieve synchrony even with
% timekeeper period (Tinit) that doesn't match the metronome period
% (stim_ioi)?
            
% print stimulus times and corresponding tap times to console
[stim_times, tap_times]

% remove first few empty taps (used to "burn in" the model)
tap_times(isnan(tap_times)) = [];

% Red dashed lines = metronome onsets
% Blue circles = simulated taps
f = figure('color','white','position',[146 596 1655 149]);

plot([stim_times, stim_times], ...
     [-1,1], ...
     ':', ...
     'color', myred, ...
     'linew', 2);

hold on

plot(tap_times, ...
     0, ...
     'o', ...
     'color', myblue, ...
     'MarkerFaceColor', myblue, ...
     'MarkerSize', 10);

box off

xlim([0, trial_dur]); 
ax = gca;
ax.Position = [0.025, 0.3, 0.95, 0.6]; 
ax.FontSize = 16;
ax.YAxis.Visible = 'off';
ax.XLim = [0, trial_dur+stim_ioi];

% Analyze simulated data using the same circular-statistics framework
phase_in_sec = mod(tap_times, stim_ioi);
phase_in_rad = phase_in_sec / stim_ioi * 2*pi;

r = abs(mean(exp(1j*phase_in_rad)));
theta = angle(mean(exp(1j*phase_in_rad)));

plot_circ( ...
    phase_in_rad, ...
    'mean_ph', theta, ...
    'r', r,...
    'col_ind', myblue,...
    'alpha_ind', 1,...
    'marker_size', 100,...
    'filled', false)

