clear 

myblue = [66, 135, 245]/255; 
myred = [209, 70, 48]/255; 

% For efficiency, we'll use some functions from rnb_tools package. Get it
% from https://github.com/TomasLenc/rnb_tools and update the path below
% accordingly. 
addpath(genpath('/Users/tomaslenc/projects_git/rnb_tools/src')); 

% We have some local helper functions in lib folder
addpath(genpath('../lib')); 

%%

% load stimulus 
stim_times = load('data/stim.mat'); 
stim_ioi = stim_times.ioi; 

% load tapping data (just one trial)
tbl = readtable('data/tap_onsets.csv'); 
tap_times = tbl.onset; 


%% 

figure('color', 'white'); 
t = [0 : length(stim_times.s)-1] / stim_times.fs; 
plot(t, stim_times.s, 'color', [.8, .8, .8], 'linew', 1)
hold on 
plot(tap_times, 0, 'o', 'MarkerFaceColor', myblue, 'MarkerEdgeColor', 'none')
box off
ax = gca; 
ax.FontSize = 18; 


%% ITIs (inter-tap intervals)

% calculate inter-tap intervals 
itis = diff(tap_times);

% plot ITI distribution
f = figure('color','white','position',[146 581 229 164]); 
h = histogram(itis, 'binedges', [stim_ioi*0.55 : 0.02 : stim_ioi*1.55]); 
hold on 
plot([stim_ioi, stim_ioi], [0, max(h.Values) * 1.2],'--','color', myred,'linew',2)
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
% Beware of outliers (pauses in tapping). Check the distribution and remove
% huge outliers manually. 

% Often best to take median anyway
mean(itis) 
median(itis)


%% phase locking with a periodic pulse (circular analysis prevents headaches)

% in this case, we don't need to match tap-target one to one

phase_in_sec = mod(tap_times, stim_ioi); 

phase_in_rad = phase_in_sec / stim_ioi * 2*pi; 

r = abs(mean(exp(1j*phase_in_rad))); 

theta = angle(mean(exp(1j*phase_in_rad))); 


f = figure('color','white','position',[146 581 229 164]); 
ax = polaraxes; 

h = polarplot(phase_in_rad, ones(length(phase_in_rad),1), 'o','color', myblue, 'linew', 1.5); 

h.MarkerSize = 10; % increase marker size

hold on

polarplot([theta,theta], [0;r], 'color', myred, 'linew',3);  

set(ax,'thetaAxisUnits','radians',...
    'thetatick',[0,pi/2,pi,3*pi/2],...
    'thetaticklabel',{'0','ioi/4','ioi/2','-ioi/4'},...
    'rtick',[],'rlim',[0,1.1], 'FontSize', 16, 'GridAlpha', 1); 


%% simulate 

stim_ioi = 0.5; 

trial_dur = 10; 

stim_times = [0 : 0.5 : trial_dur]';

tap_times = simulate_tapping(stim_times, ...
                             'alpha', 0.2, ...
                             'beta', 0.0, ...
                             'Tvar', 0.01, ...
                             'Tinit', 0.5);

[stim_times, tap_times]

tap_times(isnan(tap_times)) = []; 

f = figure('color','white','position',[146 596 1655 149]); 
plot([stim_times, stim_times],[-1,1],':','color', myred, 'linew',2); 
hold on
plot(tap_times, 0, 'o', 'color',myblue, 'MarkerFaceColor', myblue, 'MarkerSize', 10);
box off
ax = gca; 
ax.FontSize = 16; 
ax.YAxis.Visible = 'off'; 
ax.XLim = [0, trial_dur+stim_ioi]; 

      
      
phase_in_sec = mod(tap_times, stim_ioi); 
phase_in_rad = phase_in_sec / stim_ioi * 2*pi; 
itis = abs(mean(exp(1j*phase_in_rad))); 
theta = angle(mean(exp(1j*phase_in_rad))); 

plot_circ(phase_in_rad, 'mean_ph', theta, 'r', itis,...
          'col_ind', myblue, 'alpha_ind', 1, 'marker_size', 100, 'filled', false)

  
      
      
%% get asynchronies (matching tap-tone, headaches inevitable)

% Omitted taps? 
% Excluded taps? 
% Double taps? 

% Let's simulate a tapping response
% ---------------------------------

stim_ioi = 0.5; 
trial_dur = 10; 
stim_times = [0 : 0.5 : trial_dur]';
tap_times = simulate_tapping(stim_times, 'Tvar', 0.01);
tap_times(isnan(tap_times)) = []; 
% add a bit of negative mean asynchrony
tap_times = tap_times - 0.040; 
% omit a tap 
tap_times(5) = []; 
% add double tap 
tap_times(end+1) = 2.58; 
% sort the vector 
tap_times = sort(tap_times); 


% stim_ioi = 0.5; 
% trial_dur = 30; 
% stim_times = [0 : 0.5 : trial_dur]';
% tap_times = simulate_tapping(stim_times, 'Tvar', 0.05, 'alpha', 0.5);
% tap_times(isnan(tap_times)) = []; 
% tap_times = tap_times - 0.040; 
% 

    
% plot the raw tapping 
f = figure('color','white','position',[146 596 1655 149]); 
plot([stim_times, stim_times],[-1,1],':','color', myred, 'linew',2); 
hold on
plot(tap_times, 0, 'o', 'color',myblue, 'MarkerFaceColor', myblue, 'MarkerSize', 10);
box off
ax = gca; 
ax.FontSize = 16; 
ax.YAxis.Visible = 'off'; 
ax.XLim = [0, trial_dur+stim_ioi]; 


% match 1 stimulus 1 tap and get asynchronies
% -------------------------------------------

% Jacoby 2015: Note that as a preprocessing step, asynchronies larger than
% a certain threshold are identified and replaced by the mean. For example,
% for an inter-stimulus interval of about 500 ms, a reasonable threshold
% would be ~200 ms.


% tolerance (+- around each stimulus time) for assignment of taps (e.g. if
% the stimulus time is 1.000 s, then we will match all taps within from 1 -
% tap_tone_max_asy to 1 + tap_tone_max_asy 
tap_tone_max_asy = 0.200; 
% NOTE: yes, we may be ignoring taps, life if hard

% allocate mapping table 
mapping = cell(length(stim_times), 4); 

% go over stimlus times
for i_stim=1:length(stim_times)

    % stimulus onset time
    stim_time = stim_times(i_stim); 
    mapping{i_stim, 1} = stim_time; 
    
    % find taps within +- valid range 
    matching_tap_idx = find( (tap_times > stim_time-tap_tone_max_asy) & ...
                             (tap_times < stim_time+tap_tone_max_asy) ); 

    if length(matching_tap_idx) > 1
        % if we found multiple taps, take the one that's closest to the
        % stimulus
        asy = tap_times(matching_tap_idx) - stim_time; 
        [~, idx] = min(abs(asy)); 
        matching_tap_idx = matching_tap_idx(idx);         
    end
    
    % compute asynchronies
    tap_time = tap_times(matching_tap_idx); 
    asy = tap_time - stim_time; 
    
    mapping{i_stim, 2} = matching_tap_idx; 
    mapping{i_stim, 3} = tap_time; 
    mapping{i_stim, 4} = asy; 
    
end

mapping_tbl = cell2table(mapping, 'VariableNames', {'stim_time', 'tap_idx', 'tap_time' 'asynchrony'}); 
mapping_tbl

tap_times_clean = mapping_tbl.tap_time; 
% put NaNs where we have missing data
for i=1:length(tap_times_clean)
    if isempty(tap_times_clean{i})
        tap_times_clean{i} = nan; 
    end
end
% convert to a vector
tap_times_clean = cell2mat(tap_times_clean); 


asynchronies_clean = mapping_tbl.asynchrony; 
% put NaNs where we have missing data
for i=1:length(asynchronies_clean)
    if isempty(asynchronies_clean{i})
        asynchronies_clean{i} = nan; 
    end
end
% convert to a vector
asynchronies_clean = cell2mat(asynchronies_clean); 


% merge the clean data together in one structure 
data = []; 
data.stim_times = stim_times; 
data.tap_times = tap_times_clean; 
data.asy = asynchronies_clean; 

% compute IOIs and ITIs from the clean data
data.stim_ioi = diff([0; data.stim_times]); 
data.iti = diff([0; data.tap_times]); 


[data.stim_times, data.tap_times, data.asy]

% plot the clean data 
f = figure('color','white','position',[146 596 1655 149]); 
plot([data.stim_times, data.stim_times],[-1,1],':','color', myred, 'linew',2); 
hold on
plot(data.tap_times, 0, 'o', 'color',myblue, 'MarkerFaceColor', myblue, 'MarkerSize', 10);
box off
ax = gca; 
ax.FontSize = 16; 
ax.YAxis.Visible = 'off'; 
ax.XLim = [0, trial_dur+stim_ioi]; 




%%

% compute mean asynchrony 
mean_asy = nanmean(data.asy)

% standard deviation of asynchronies 
sd_asy = nanstd(data.asy)

% first two taps don't count (they will be nans anyway)
n_max_possible_taps = length(data.stim_times) - 2;   
% find proportion of missing taps (if it's over ~40%, we should reject the
% trial)
prop_missing = sum(isnan(data.asy)) / n_max_possible_taps


%% phase correction 

% ---------------
% autocorrelation 
% ---------------

% Vishne (2021): To test the efficiency of online phase correction we
% calculated the correlation between consecutive asynchronies (errors). Any
% positive correlation means that errors tend to persist across beats, and
% a correlation of one means that errors are fully retained across
% consecutive beats. A correlation of zero means that errors were not
% carried across trials, and negative correlations mean overcorrection.

lag = 1;
start_offset = 3;

vec_all_e = [];

subj_e = [];

asy = data.asy; 

asy = asy - nanmean(asy(start_offset:end));

lagged_asy = [asy(start_offset:(end-lag)), asy((start_offset+lag):end)];

corr(lagged_asy(:,1), lagged_asy(:,2), 'Rows','complete')


% ---------------
% bGLS 
% ---------------

start_offset = 3;

% take out the asynchronies
asy = data.asy(start_offset : end); 

% take out the inter-tap intervals
itis = data.iti(start_offset : end); 

% get the means (ignore NaNs)
mean_asy = nanmean(asy);
mean_iti = nanmean(itis);

% fit the model  
[alpha_hat, T_hat, M_hat] = bGLS_phase_corr(itis, asy, mean_asy, mean_iti);

alpha_hat


            
%% period correction 


% ....to do







